# deployment-monitor

Lists the runs of a Managed Agents deployment, opens the event stream of the newest run's session,
sends one `user.message`, and prints the agent's reply as it streams.

```bash
pip install -r requirements.txt
export ANTHROPIC_API_KEY=...   # or: ant auth login
python monitor.py                                   # default deployment depl_013jJBeX1QSFgUqsYMSxLexT
python monitor.py --message "What did you find?"
```

Exit code 0 when the turn ends normally (`end_turn`), 1 on errors, termination or other stop reasons.
Tool approvals (`requires_action`) are not answered - the script only reports them.

## Web-App

Eine Seite im Browser: Runs als Liste, Run antippen, Nachricht schreiben, Antwort kommt live.
Der API-Schlüssel bleibt auf dem Server (`web/app.py`), der Browser sieht ihn nie.

```bash
pip install -r requirements.txt
export ANTHROPIC_API_KEY=...
python web/app.py            # dann http://127.0.0.1:8000 öffnen
HOST=0.0.0.0 python web/app.py   # auch vom Handy im selben WLAN erreichbar
```

Die App hat kein Login: Wer die Seite erreicht, kann mit dem Agent schreiben. Darum läuft sie
standardmäßig nur auf dem eigenen Computer. Sie lässt nur Sessions aus diesem Deployment zu.
