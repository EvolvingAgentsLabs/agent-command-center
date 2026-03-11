---
description: Start a watcher that monitors agents and auto-prompts idle ones
---

# Agent Command Center - Watch

Start the ACC watcher that continuously monitors all agent panes and automatically re-prompts any that become idle.

**Arguments:** `$ARGUMENTS`

Parse options:
- **prompt**: Custom re-prompt message (default: "Continue working on your task. If you've completed it, summarize what you did.")
- **interval**: Check interval in seconds (default: 30, parse from `--interval N` or `-i N`)
- **max-nudges**: Maximum times to nudge a single agent before giving up (default: 5, parse from `--max-nudges N`)
- **filter**: Only watch specific windows/panes (parse from `--filter PATTERN`)

## Steps

1. **Create the watcher script** in a temporary location:

Write a bash script that:

```bash
#!/usr/bin/env bash
# ACC Watcher - Auto-prompts idle Claude Code agents
# Usage: acc-watcher.sh [--interval SECONDS] [--prompt "MESSAGE"] [--max-nudges N]

INTERVAL="${ACC_WATCH_INTERVAL:-30}"
PROMPT="${ACC_WATCH_PROMPT:-Continue working on your task. If you have completed it, summarize what you did.}"
MAX_NUDGES="${ACC_WATCH_MAX_NUDGES:-5}"
SESSION="acc"

declare -A nudge_counts

echo "ACC Watcher started"
echo "  Session:    $SESSION"
echo "  Interval:   ${INTERVAL}s"
echo "  Max nudges: $MAX_NUDGES"
echo "  Prompt:     $PROMPT"
echo "  $(date '+%H:%M:%S') Watching..."
echo ""

while true; do
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "  [$(date '+%H:%M:%S')] No ACC session found. Waiting..."
        sleep "$INTERVAL"
        continue
    fi

    panes=$(tmux list-panes -a -t "$SESSION" -F '#{window_index}.#{pane_index}|#{window_name}')

    while IFS='|' read -r pane_id pane_name; do
        [ -z "$pane_id" ] && continue

        # Capture last 5 lines of the pane
        content=$(tmux capture-pane -t "${SESSION}:${pane_id}" -p -S -5 2>/dev/null)

        # Check if agent is idle (waiting for input, not showing active indicators)
        is_idle=false

        # Active indicators - agent is working
        if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
            is_idle=false
        # Idle indicators - agent finished and waiting
        elif echo "$content" | grep -qE "^(>|❯|\$|claude>|%)" || \
             echo "$content" | grep -qE "(What would you like|How can I help|Is there anything else)"; then
            is_idle=true
        fi

        if $is_idle; then
            key="${pane_id}"
            count=${nudge_counts[$key]:-0}

            if [ "$count" -lt "$MAX_NUDGES" ]; then
                nudge_counts[$key]=$((count + 1))
                echo "  [$(date '+%H:%M:%S')] Nudging ${pane_name:-$pane_id} (${nudge_counts[$key]}/$MAX_NUDGES)"
                tmux send-keys -t "${SESSION}:${pane_id}" "$PROMPT" Enter
            elif [ "$count" -eq "$MAX_NUDGES" ]; then
                nudge_counts[$key]=$((count + 1))
                echo "  [$(date '+%H:%M:%S')] ${pane_name:-$pane_id} reached max nudges ($MAX_NUDGES). Stopping."
            fi
        else
            # Reset nudge count when agent becomes active again
            nudge_counts[$pane_id]=0
        fi
    done <<< "$panes"

    sleep "$INTERVAL"
done
```

2. **Write this script** to a temp file and make it executable:
   ```
   Write the script to /tmp/acc-watcher.sh
   chmod +x /tmp/acc-watcher.sh
   ```

3. **Launch the watcher** in a dedicated tmux window:
   ```
   tmux has-session -t acc 2>/dev/null || tmux new-session -d -s acc
   tmux new-window -t acc -n "watcher"
   tmux send-keys -t acc:watcher "ACC_WATCH_INTERVAL={interval} ACC_WATCH_PROMPT='{prompt}' ACC_WATCH_MAX_NUDGES={max_nudges} /tmp/acc-watcher.sh" Enter
   ```

4. **Report to the user:**
   ```
   ACC Watcher started in acc:watcher
   - Checking every {interval}s for idle agents
   - Will auto-prompt with: "{prompt}"
   - Max nudges per agent: {max_nudges}

   To stop: /acc:kill watcher
   To view: tmux select-window -t acc:watcher
   ```

## Example usage

Default watcher:
```
/acc:watch
```

Custom prompt and interval:
```
/acc:watch --interval 15 Continue your research, focus on finding security vulnerabilities
```

Conservative watcher:
```
/acc:watch --max-nudges 2 --interval 60
```
