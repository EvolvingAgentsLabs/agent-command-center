#!/usr/bin/env bash
# ACC Dashboard - Rich terminal dashboard for the Agent Command Center
# Usage: acc-dashboard.sh [--once] [--interval N]
# Default: refreshes every 5 seconds. --once for single snapshot.

SESSION="${ACC_SESSION:-acc}"
INTERVAL="${1:-5}"
ONCE=false

for arg in "$@"; do
    case "$arg" in
        --once) ONCE=true ;;
        --interval) shift; INTERVAL="${1:-5}" ;;
    esac
done

render_dashboard() {
    clear 2>/dev/null || true

    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
        echo "╔══════════════════════════════════════════════════════════════════╗"
        echo "║                     AGENT COMMAND CENTER                        ║"
        echo "╠══════════════════════════════════════════════════════════════════╣"
        echo "║  No ACC session found.                                          ║"
        echo "║  Use /acc:launch to start agents.                               ║"
        echo "╚══════════════════════════════════════════════════════════════════╝"
        return
    fi

    local active=0 idle=0 blocked=0 errored=0 total=0
    local agents=""

    while IFS='|' read -r pane_id window_name pane_pid; do
        [ -z "$pane_id" ] && continue
        total=$((total + 1))

        # Duration
        local duration="N/A"
        if [ -n "$pane_pid" ]; then
            duration=$(ps -o etime= -p "$pane_pid" 2>/dev/null | xargs 2>/dev/null || echo "N/A")
        fi

        # Capture output
        local content
        content=$(tmux capture-pane -t "${SESSION}:${pane_id}" -p -S -15 2>/dev/null)
        local last_line
        last_line=$(echo "$content" | grep -v '^$' | tail -1 | cut -c1-50)

        # Classify
        local status="ACTIVE" indicator="●"
        if echo "$content" | grep -qE "(esc to interrupt|Thinking|Reading|Writing|Editing|Searching|Running)"; then
            status="ACTIVE"; indicator="●"; active=$((active + 1))
        elif echo "$content" | grep -qE "(Allow|approve|confirm|Do you want|Y/n|y/N)"; then
            status="BLOCKED"; indicator="◉"; blocked=$((blocked + 1))
        elif echo "$content" | grep -qE "(Error:|error:|ERROR|Traceback|panic:)"; then
            status="ERRORED"; indicator="✗"; errored=$((errored + 1))
        elif echo "$content" | grep -qE "^(>|❯|\\\$|claude>|%)" || \
             echo "$content" | grep -qE "(What would you like|How can I help|Is there anything)"; then
            status="IDLE"; indicator="○"; idle=$((idle + 1))
        else
            active=$((active + 1))
        fi

        agents+="  [$total] ${window_name:-pane-$pane_id} ($pane_id)$(printf '%*s' $((40 - ${#window_name:-6} - ${#pane_id})) '')$indicator $status  [$duration]\n"
        agents+="      Last: $last_line\n"
        agents+="\n"

    done < <(tmux list-panes -a -t "$SESSION" -F '#{window_index}.#{pane_index}|#{window_name}|#{pane_pid}')

    # Resource usage
    local resource_info
    resource_info=$(ps aux 2>/dev/null | grep -E '(claude|node)' | grep -v grep | \
        awk '{cpu+=$3; mem+=$4; count++} END {printf "Procs: %d  CPU: %.1f%%  MEM: %.1f%%", count, cpu, mem}' 2>/dev/null || echo "N/A")

    # Render
    local now
    now=$(date '+%H:%M:%S')

    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                     AGENT COMMAND CENTER                        ║"
    echo "║                     ═══════════════════                         ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    printf "║  Session: %-8s  Agents: %-3s  Active: %-2s  Idle: %-2s  Blocked: %-2s  ║\n" "$SESSION" "$total" "$active" "$idle" "$blocked"
    printf "║  Time: %s     %s            ║\n" "$now" "$resource_info"
    echo "║                                                                  ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║                                                                  ║"
    printf "%b" "$agents"
    echo "╠══════════════════════════════════════════════════════════════════╣"

    if [ "$idle" -gt 0 ]; then
        echo "║  Hint: /acc:nudge to re-prompt idle agents                      ║"
    fi
    if [ "$blocked" -gt 0 ]; then
        echo "║  Hint: /acc:approve to approve blocked agents                   ║"
    fi
    if [ "$idle" -eq 0 ] && [ "$blocked" -eq 0 ]; then
        echo "║  All agents are working. Looking good!                          ║"
    fi
    echo "╚══════════════════════════════════════════════════════════════════╝"
}

if $ONCE; then
    render_dashboard
else
    echo "ACC Dashboard - Press Ctrl+C to exit (refreshing every ${INTERVAL}s)"
    while true; do
        render_dashboard
        sleep "$INTERVAL"
    done
fi
