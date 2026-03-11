---
description: Show a rich dashboard of all agents with stats, progress, and resource usage
---

# Agent Command Center - Dashboard

Display a comprehensive dashboard showing all managed agents, their status, recent activity, and resource metrics.

**Arguments:** `$ARGUMENTS`

Options:
- `--watch` or `-w`: Suggest the user run the dashboard script in a separate terminal for live updates
- `--compact` or `-c`: Show a compact single-line-per-agent view

## Steps

1. **Check for ACC session:**
   ```
   tmux has-session -t acc 2>/dev/null || { echo "No ACC session found. Use /acc:launch to start agents."; exit 1; }
   ```

2. **Gather data for each pane:**

   a. List all panes:
   ```
   tmux list-panes -a -t acc -F '#{session_name}:#{window_index}.#{pane_index}|#{window_name}|#{pane_pid}|#{pane_width}x#{pane_height}|#{pane_current_command}'
   ```

   b. For each pane, capture recent output (last 30 lines) to analyze:
   ```
   tmux capture-pane -t acc:{w}.{p} -p -S -30
   ```

   c. Determine each agent's:
   - **Status**: ACTIVE / IDLE / BLOCKED / ERRORED / COMPLETED (same heuristics as /acc:status)
   - **Current task**: Try to extract from the initial prompt or recent context
   - **Last output snippet**: Last meaningful 1-2 lines of output
   - **Duration**: How long the pane has been running via `ps -o etime= -p {pid}`

3. **Check system resources:**
   ```
   # CPU and memory overview
   ps aux | grep -E 'claude|node' | grep -v grep | awk '{cpu+=$3; mem+=$4; count++} END {printf "Processes: %d, CPU: %.1f%%, MEM: %.1f%%\n", count, cpu, mem}'
   ```

4. **Render the dashboard:**

```
╔══════════════════════════════════════════════════════════════════════╗
║                    AGENT COMMAND CENTER                              ║
║                    ═══════════════════                               ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  Session: acc    Agents: 4    Active: 2   Idle: 1   Blocked: 1      ║
║  Uptime: 1h 23m              CPU: 12.3%  MEM: 8.4%                  ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  [1] api-refactor (0.0)                         ● ACTIVE  [34m]    ║
║      Task: Refactor API endpoints to async/await                     ║
║      Last: Editing src/routes/users.ts...                            ║
║                                                                      ║
║  [2] test-writer (0.1)                          ● ACTIVE  [12m]    ║
║      Task: Write tests for utils module                              ║
║      Last: Running test suite...                                     ║
║                                                                      ║
║  [3] bug-fix (1.0)                              ○ IDLE    [45m]    ║
║      Task: Fix auth bug                                              ║
║      Last: Waiting for input                                         ║
║                                                                      ║
║  [4] docs (1.1)                                 ◉ BLOCKED [8m]     ║
║      Task: Update API documentation                                  ║
║      Last: Allow Write to docs/api.md?                               ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  Hint: /acc:nudge to re-prompt idle agents                           ║
║        /acc:approve 4 to approve blocked agent                       ║
╚══════════════════════════════════════════════════════════════════════╝
```

5. If `--watch` was specified, tell the user:
   ```
   For live updates, run in a separate terminal:
   watch -n 5 'tmux list-panes -a -t acc -F "#{window_name} #{pane_index}" && echo "---" && for p in $(tmux list-panes -a -t acc -F "#{window_index}.#{pane_index}"); do echo "=== $p ==="; tmux capture-pane -t "acc:$p" -p -S -3; done'
   ```

Adapt the layout based on the actual number of agents found. If no agents are running, show an empty dashboard with a hint to use `/acc:launch`.
