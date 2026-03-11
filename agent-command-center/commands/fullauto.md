---
description: Enable fully automatic mode - agent loops until manually stopped
---

# Agent Command Center - Full Auto

Enable fully automatic mode for an agent. The agent will continue working autonomously, re-injecting the given prompt whenever it becomes idle, until manually stopped.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **target**: Window name or pane ID to put in fullauto mode (e.g., `0.0`, `api-refactor`). If `--all`, apply to all panes.
- **prompt**: The prompt to re-inject when the agent idles (everything after the target, or from `--prompt "..."`)
- If no prompt given, default: "Continue working. You must not stop until the task is fully complete. If blocked, try alternative approaches. If truly done, write a completion summary."

## Steps

1. **Resolve the target pane(s):**

   If a window name was given:
   ```
   tmux list-panes -t acc:{name} -F '#{window_index}.#{pane_index}' 2>/dev/null
   ```

   If `--all`:
   ```
   tmux list-panes -a -t acc -F '#{window_index}.#{pane_index}' 2>/dev/null
   ```

2. **Create the fullauto watcher script** tailored for aggressive re-prompting:

```bash
#!/usr/bin/env bash
# ACC FullAuto - Aggressive auto-continue for a specific agent
# Unlike the regular watcher, this has NO nudge limit and shorter intervals

SESSION="acc"
PANE="$1"
PROMPT="${2:-Continue working. You must not stop until the task is fully complete. If blocked, try alternative approaches. If truly done, write a completion summary.}"
INTERVAL=10

echo "FULLAUTO engaged for acc:${PANE}"
echo "  Prompt: $PROMPT"
echo "  Press Ctrl+C to disengage"
echo ""

while true; do
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] Session gone. Exiting."
        exit 0
    fi

    content=$(tmux capture-pane -t "${SESSION}:${PANE}" -p -S -5 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "[$(date '+%H:%M:%S')] Pane gone. Exiting."
        exit 0
    fi

    # Check if agent is waiting for input (idle)
    if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
        : # Still working, do nothing
    elif echo "$content" | grep -qE "^(>|❯|\$|claude>|%)" || \
         echo "$content" | grep -qE "(What would you like|How can I help|Is there anything else|Task completed|I've completed)"; then
        echo "[$(date '+%H:%M:%S')] Agent idle - re-injecting prompt"
        tmux send-keys -t "${SESSION}:${PANE}" "$PROMPT" Enter
    elif echo "$content" | grep -qE "(Allow|approve|confirm|Do you want|Y/n|y/N)"; then
        echo "[$(date '+%H:%M:%S')] Agent needs approval - sending 'y'"
        tmux send-keys -t "${SESSION}:${PANE}" "y" Enter
    fi

    sleep "$INTERVAL"
done
```

3. **Deploy and start the fullauto script:**
   ```
   # Write the script
   Write script to /tmp/acc-fullauto-{pane_id}.sh
   chmod +x /tmp/acc-fullauto-{pane_id}.sh

   # Launch in a monitoring window
   tmux new-window -t acc -n "fullauto-{pane_id}"
   tmux send-keys -t acc:fullauto-{pane_id} "/tmp/acc-fullauto-{pane_id}.sh '{pane_id}' '{prompt}'" Enter
   ```

4. **Report:**
   ```
   FULLAUTO engaged for acc:{target}
   - Agent will auto-continue every 10s when idle
   - Approvals will be auto-accepted
   - Monitor at: tmux select-window -t acc:fullauto-{pane_id}
   - Disengage with: /acc:kill fullauto-{pane_id}

   WARNING: Auto-approval is enabled. The agent will accept all permission
   prompts automatically. Use with caution on trusted tasks only.
   ```

## Examples

```
/acc:fullauto 0.0 Continue your research on the codebase, document all API endpoints
```

```
/acc:fullauto api-refactor You must complete the full refactor. Don't stop.
```

```
/acc:fullauto --all Keep going until all tasks are done
```
