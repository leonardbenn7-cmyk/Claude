"""Kleine Web-App: zeigt die Runs eines Managed-Agents-Deployments und chattet mit der Session eines Runs.

Der API-Schlüssel bleibt auf diesem Server - der Browser sieht ihn nie.
"""

import json
import os

import anthropic
from flask import Flask, Response, jsonify, request, send_from_directory, stream_with_context

DEPLOYMENT_ID = os.environ.get("DEPLOYMENT_ID", "depl_013jJBeX1QSFgUqsYMSxLexT")

app = Flask(__name__, static_folder="static")
_client = None


def get_client() -> anthropic.Anthropic:
    global _client
    if _client is None:
        _client = anthropic.Anthropic()  # ANTHROPIC_API_KEY oder `ant auth login`
    return _client


def api_error_text(e: Exception) -> str:
    if isinstance(e, anthropic.AuthenticationError):
        return "Kein gültiger API-Schlüssel auf dem Server."
    if isinstance(e, anthropic.NotFoundError):
        return "Nicht gefunden - stimmt die Deployment-ID?"
    if isinstance(e, anthropic.RateLimitError):
        return "Zu viele Anfragen - bitte kurz warten."
    if isinstance(e, anthropic.APIStatusError):
        return f"API-Fehler {e.status_code}: {e.message}"
    if isinstance(e, anthropic.APIConnectionError):
        return "Anthropic-API nicht erreichbar."
    return f"Fehler: {e}"


def list_runs():
    runs = list(get_client().beta.deployment_runs.list(deployment_id=DEPLOYMENT_ID))
    runs.sort(key=lambda r: r.created_at, reverse=True)
    return runs


@app.get("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/api/runs")
def runs():
    try:
        data = [
            {
                "id": r.id,
                "created_at": r.created_at.isoformat() if hasattr(r.created_at, "isoformat") else str(r.created_at),
                "session_id": r.session_id,
                "error": r.error.type if r.error else None,
            }
            for r in list_runs()
        ]
        return jsonify({"deployment_id": DEPLOYMENT_ID, "runs": data})
    except (anthropic.AnthropicError, anthropic.APIError) as e:
        return jsonify({"error": api_error_text(e)}), 502


@app.post("/api/chat")
def chat():
    body = request.get_json(silent=True) or {}
    session_id = body.get("session_id", "")
    message = (body.get("message") or "").strip()
    if not message:
        return jsonify({"error": "Nachricht ist leer."}), 400

    # Nur Sessions aus diesem Deployment zulassen.
    try:
        allowed = {r.session_id for r in list_runs() if r.session_id}
    except (anthropic.AnthropicError, anthropic.APIError) as e:
        return jsonify({"error": api_error_text(e)}), 502
    if session_id not in allowed:
        return jsonify({"error": "Diese Session gehört nicht zum Deployment."}), 400

    def line(**kw):
        return json.dumps(kw) + "\n"

    def generate():
        client = get_client()
        try:
            # Erst Stream öffnen, dann senden - sonst kommen frühe Events gebündelt am Ende.
            with client.beta.sessions.events.stream(session_id=session_id) as stream:
                client.beta.sessions.events.send(
                    session_id=session_id,
                    events=[{"type": "user.message", "content": [{"type": "text", "text": message}]}],
                )
                for event in stream:
                    if event.type == "agent.message":
                        for block in event.content:
                            if block.type == "text":
                                yield line(type="text", text=block.text)
                    elif event.type == "session.error":
                        yield line(type="status", text="Fehler in der Session (Agent versucht es evtl. weiter).")
                    elif event.type == "session.status_idle":
                        reason = event.stop_reason.type
                        if reason == "requires_action":
                            yield line(type="status", text="Agent wartet auf eine Tool-Freigabe - das kann diese App nicht.")
                            continue
                        yield line(type="done", reason=reason)
                        return
                    elif event.type == "session.status_terminated":
                        yield line(type="done", reason="terminated")
                        return
            yield line(type="error", text="Verbindung beendet, bevor der Agent fertig war.")
        except (anthropic.AnthropicError, anthropic.APIError) as e:
            yield line(type="error", text=api_error_text(e))

    return Response(stream_with_context(generate()), mimetype="application/x-ndjson",
                    headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})


if __name__ == "__main__":
    # Standardmäßig nur auf diesem Computer erreichbar. HOST=0.0.0.0 öffnet es fürs WLAN.
    app.run(host=os.environ.get("HOST", "127.0.0.1"), port=int(os.environ.get("PORT", "8000")), threaded=True)
