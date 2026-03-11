#!/usr/bin/env bash
# ACC FullAuto - Aggressive auto-continue for a specific agent
# Usage: acc-fullauto.sh <pane_id> [prompt]
# Unlike the regular watcher, this has NO nudge limit and shorter check intervals

set -euo pipefail

SESSION="${ACC_SESSION:-acc}"
PANE="${1:?Usage: acc-fullauto.sh <pane_id> [prompt]}"
PROMPT="${2:-Continue working. You must not stop until the task is fully complete. If blocked, try alternative approaches. If truly done, write a completion summary.}"
INTERVAL="${ACC_FULLAUTO_INTERVAL:-10}"

echo "╔══════════════════════════════════════╗"
echo "║      ACC FullAuto - Engaged          ║"
echo "╠══════════════════════════════════════╣"
echo "║  Pane:     $PANE"
echo "║  Interval: ${INTERVAL}s"
echo "║  Prompt:   ${PROMPT:0:40}..."
echo "║  Press Ctrl+C to disengage           ║"
echo "╚══════════════════════════════════════╝"
echo ""

nudge_count=0

cleanup() {
    echo ""
    echo "[$(date '+%H:%M:%S')] FullAuto disengaged after $nudge_count nudges"
    exit 0
}
trap cleanup INT TERM

while true; do
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] Session '$SESSION' gone. Exiting."
        exit 0
    fi

    content=$(tmux capture-pane -t "${SESSION}:${PANE}" -p -S -5 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "[$(date '+%H:%M:%S')] Pane ${PANE} gone. Exiting."
        exit 0
    fi

    # Check if actively working
    if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
        : # Working, do nothing
    # Check if blocked on approval
    elif echo "$content" | grep -qE "(Allow|approve|confirm|Do you want|Y/n|y/N)"; then
        echo "[$(date '+%H:%M:%S')] Agent needs approval - auto-approving"
        tmux send-keys -t "${SESSION}:${PANE}" "y" Enter
        nudge_count=$((nudge_count + 1))
    # Check if idle
    elif echo "$content" | grep -qE "^(>|❯|\$|claude>|%)" || \
         echo "$content" | grep -qE "(What would you like|How can I help|Is there anything|I've completed|Task completed|I have completed)"; then
        nudge_count=$((nudge_count + 1))
        echo "[$(date '+%H:%M:%S')] Agent idle - re-injecting prompt (#$nudge_count)"
        tmux send-keys -t "${SESSION}:${PANE}" "$PROMPT" Enter
    fi

    sleep "$INTERVAL"
done
