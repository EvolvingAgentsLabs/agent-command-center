#!/usr/bin/env bash
# ACC Status - Quick status check for all agent panes
# Usage: acc-status.sh [session_name]

SESSION="${1:-acc}"

if ! command -v tmux &>/dev/null; then
    echo "ERROR: tmux is not installed"
    exit 1
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "No ACC session found. Use /acc:launch to start agents."
    exit 0
fi

active=0
idle=0
blocked=0
errored=0
completed=0
total=0

echo "Agent Command Center - Status"
echo "══════════════════════════════════════════════════════════════"
printf " %-3s │ %-14s │ %-10s │ %-10s │ %s\n" "#" "Window.Pane" "Status" "Duration" "Last Activity"
echo "─────┼────────────────┼────────────┼────────────┼─────────────────────"

while IFS='|' read -r pane_id window_name pane_pid; do
    [ -z "$pane_id" ] && continue
    total=$((total + 1))

    # Get duration
    duration=""
    if [ -n "$pane_pid" ] && [ "$pane_pid" != "" ]; then
        duration=$(ps -o etime= -p "$pane_pid" 2>/dev/null | xargs)
    fi

    # Capture last 5 lines
    content=$(tmux capture-pane -t "${SESSION}:${pane_id}" -p -S -5 2>/dev/null)
    last_line=$(echo "$content" | grep -v '^$' | tail -1 | cut -c1-40)

    # Classify status
    status="UNKNOWN"
    if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
        status="ACTIVE"
        active=$((active + 1))
    elif echo "$content" | grep -qE "(Allow|approve|confirm|Do you want|Y/n|y/N)"; then
        status="BLOCKED"
        blocked=$((blocked + 1))
    elif echo "$content" | grep -qE "(Error:|error:|ERROR|Traceback|panic:)"; then
        status="ERRORED"
        errored=$((errored + 1))
    elif echo "$content" | grep -qE "^(>|❯|\\\$|claude>|%)" || \
         echo "$content" | grep -qE "(What would you like|How can I help|Is there anything)"; then
        status="IDLE"
        idle=$((idle + 1))
    else
        status="ACTIVE"
        active=$((active + 1))
    fi

    # Status indicator
    case "$status" in
        ACTIVE)    indicator="●" ;;
        IDLE)      indicator="○" ;;
        BLOCKED)   indicator="◉" ;;
        ERRORED)   indicator="✗" ;;
        *)         indicator="?" ;;
    esac

    name_display="${window_name:-$pane_id}"
    printf " %-3s │ %-14s │ %s %-8s │ %-10s │ %s\n" \
        "$total" "$name_display" "$indicator" "$status" "${duration:-N/A}" "$last_line"

done < <(tmux list-panes -a -t "$SESSION" -F '#{window_index}.#{pane_index}|#{window_name}|#{pane_pid}')

echo "══════════════════════════════════════════════════════════════"
echo " Active: $active  Idle: $idle  Blocked: $blocked  Errored: $errored  Total: $total"

if [ "$idle" -gt 0 ]; then
    echo ""
    echo " Hint: Run /acc:nudge to re-prompt idle agents"
fi

if [ "$blocked" -gt 0 ]; then
    echo " Hint: Run /acc:approve to approve blocked agents"
fi
