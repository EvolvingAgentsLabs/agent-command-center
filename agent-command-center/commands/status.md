---
description: Show the status of all running agent sessions in tmux
---

# Agent Command Center - Status

Check the status of all managed agent panes in the ACC tmux session.

Run the ACC status script to discover all agent panes:

```
bash "$(dirname "$(find . -path '*/agent-command-center/scripts/acc-status.sh' 2>/dev/null | head -1)" || echo scripts)/acc-status.sh"
```

If the script is not found, perform the check manually:

1. First check if tmux is running and an `acc` session exists:
   ```
   tmux has-session -t acc 2>/dev/null && echo "ACC session active" || echo "No ACC session found"
   ```

2. List all panes in the `acc` session with their current content:
   ```
   tmux list-panes -t acc -F '#{window_index}.#{pane_index} #{pane_title} #{pane_width}x#{pane_height}' 2>/dev/null
   ```

3. For each pane, capture the last 5 lines to determine status:
   ```
   tmux capture-pane -t acc:{window}.{pane} -p -S -5
   ```

4. Classify each agent as:
   - **ACTIVE** - if output contains "esc to interrupt" or shows streaming output
   - **IDLE** - if output shows a prompt like `>`, `$`, or `claude>` waiting for input
   - **BLOCKED** - if output shows an approval prompt like "Allow?" or "Do you want to proceed?"
   - **ERRORED** - if output contains error messages or stack traces
   - **COMPLETED** - if the agent has exited or the pane shows a shell prompt after the agent finished

Present the results as a formatted table:

```
Agent Command Center - Status
═══════════════════════════════════════
 #  │ Window.Pane │ Status    │ Last Activity
────┼─────────────┼───────────┼──────────────
 1  │ 0.0         │ ACTIVE    │ Writing code...
 2  │ 0.1         │ IDLE      │ Waiting for input
 3  │ 1.0         │ BLOCKED   │ Needs approval
═══════════════════════════════════════
Active: X  Idle: X  Blocked: X  Total: X
```

If no `acc` session exists, inform the user they can create one with `/acc:launch`.
