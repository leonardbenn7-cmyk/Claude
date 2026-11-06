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
