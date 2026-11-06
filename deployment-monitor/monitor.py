"""Monitor a Managed Agents deployment: find its latest run, talk to that session, print the reply."""

import argparse
import sys

import anthropic

DEFAULT_DEPLOYMENT_ID = "depl_013jJBeX1QSFgUqsYMSxLexT"


def latest_run_with_session(client: anthropic.Anthropic, deployment_id: str):
    """Return the newest deployment run that created a session (failed runs have no session_id)."""
    runs = list(client.beta.deployment_runs.list(deployment_id=deployment_id))
    for run in runs:
        status = run.session_id or f"failed: {run.error.type}"
        print(f"  {run.id}  {run.created_at}  {status}")
    with_session = [r for r in runs if r.session_id]
    if not with_session:
        return None
    return max(with_session, key=lambda r: r.created_at)


def stream_reply(client: anthropic.Anthropic, session_id: str, text: str) -> int:
    """Open the stream first, then send the message, then print agent text until the turn ends."""
    with client.beta.sessions.events.stream(session_id=session_id) as stream:
        client.beta.sessions.events.send(
            session_id=session_id,
            events=[{"type": "user.message", "content": [{"type": "text", "text": text}]}],
        )
        for event in stream:
            if event.type == "agent.message":
                for block in event.content:
                    if block.type == "text":
                        print(block.text, end="", flush=True)
            elif event.type == "session.error":
                print(f"\n[session error] {event}", file=sys.stderr)
            elif event.type == "session.status_idle":
                reason = event.stop_reason.type
                if reason == "requires_action":
                    # Agent waits for a tool approval / tool result. This minimal monitor doesn't answer those.
                    print("\n[waiting on a tool approval - not handled here]", file=sys.stderr)
                    continue
                print(f"\n--- idle ({reason}) ---")
                return 0 if reason == "end_turn" else 1
            elif event.type == "session.status_terminated":
                print("\n--- session terminated ---")
                return 1
    print("\n[stream closed before the session went idle]", file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--deployment", default=DEFAULT_DEPLOYMENT_ID)
    parser.add_argument("--message", default="Give me a short status update on this run.")
    args = parser.parse_args()

    client = anthropic.Anthropic()  # API key from ANTHROPIC_API_KEY or an `ant auth login` profile

    try:
        print(f"Runs for {args.deployment}:")
        run = latest_run_with_session(client, args.deployment)
        if run is None:
            print("No run with a session yet.", file=sys.stderr)
            return 1
        print(f"\nLatest session: {run.session_id}\n")
        return stream_reply(client, run.session_id, args.message)
    except anthropic.AuthenticationError:
        print("Error: no valid API key (set ANTHROPIC_API_KEY or run `ant auth login`).", file=sys.stderr)
    except anthropic.NotFoundError as e:
        print(f"Error: not found - check the deployment ID. {e.message}", file=sys.stderr)
    except anthropic.RateLimitError:
        print("Error: rate limited - try again later.", file=sys.stderr)
    except anthropic.APIStatusError as e:
        print(f"API error {e.status_code}: {e.message}", file=sys.stderr)
    except anthropic.APIConnectionError:
        print("Error: could not reach the Anthropic API.", file=sys.stderr)
    except KeyboardInterrupt:
        print("\nStopped.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
