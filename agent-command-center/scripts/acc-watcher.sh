#!/usr/bin/env bash
# ACC Watcher - Auto-prompts idle Claude Code agents
# Usage: acc-watcher.sh
# Environment variables:
#   ACC_WATCH_INTERVAL  - Check interval in seconds (default: 30)
#   ACC_WATCH_PROMPT    - Re-prompt message (default: "Continue working on your task...")
#   ACC_WATCH_MAX_NUDGES - Max nudges per agent before stopping (default: 5)
#   ACC_SESSION         - tmux session name (default: acc)

set -euo pipefail

SESSION="${ACC_SESSION:-acc}"
INTERVAL="${ACC_WATCH_INTERVAL:-30}"
PROMPT="${ACC_WATCH_PROMPT:-Continue working on your task. If you have completed it, summarize what you did.}"
MAX_NUDGES="${ACC_WATCH_MAX_NUDGES:-5}"

declare -A nudge_counts 2>/dev/null || {
    echo "ERROR: Bash 4+ required for associative arrays"
    exit 1
}

echo "╔══════════════════════════════════════╗"
echo "║     ACC Watcher - Agent Monitor      ║"
echo "╠══════════════════════════════════════╣"
echo "║  Session:    $SESSION"
echo "║  Interval:   ${INTERVAL}s"
echo "║  Max nudges: $MAX_NUDGES"
echo "║  Prompt:     ${PROMPT:0:40}..."
echo "╚══════════════════════════════════════╝"
echo ""
echo "[$(date '+%H:%M:%S')] Watching for idle agents..."
echo ""

while true; do
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] No ACC session found. Waiting..."
        sleep "$INTERVAL"
        continue
    fi

    pane_list=$(tmux list-panes -a -t "$SESSION" -F '#{window_index}.#{pane_index}|#{window_name}' 2>/dev/null || true)

    while IFS='|' read -r pane_id pane_name; do
        [ -z "$pane_id" ] && continue

        # Capture last 5 lines
        content=$(tmux capture-pane -t "${SESSION}:${pane_id}" -p -S -5 2>/dev/null || true)
        [ -z "$content" ] && continue

        is_idle=false

        # Check active indicators first
        if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
            # Agent is working - reset nudge count
            nudge_counts["$pane_id"]=0
            continue
        fi

        # Check idle indicators
        if echo "$content" | grep -qE "^(>|❯|\$|claude>|%)" || \
           echo "$content" | grep -qE "(What would you like|How can I help|Is there anything else)"; then
            is_idle=true
        fi

        if $is_idle; then
            count=${nudge_counts["$pane_id"]:-0}

            if [ "$count" -lt "$MAX_NUDGES" ]; then
                nudge_counts["$pane_id"]=$((count + 1))
                echo "[$(date '+%H:%M:%S')] Nudging ${pane_name:-$pane_id} (${nudge_counts[$pane_id]}/$MAX_NUDGES)"
                tmux send-keys -t "${SESSION}:${pane_id}" "$PROMPT" Enter
            elif [ "$count" -eq "$MAX_NUDGES" ]; then
                nudge_counts["$pane_id"]=$((count + 1))
                echo "[$(date '+%H:%M:%S')] ${pane_name:-$pane_id} hit max nudges ($MAX_NUDGES). Will not nudge again."
            fi
        fi
    done <<< "$pane_list"

    sleep "$INTERVAL"
done
