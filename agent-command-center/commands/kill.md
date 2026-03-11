---
description: Stop and clean up agent sessions
---

# Agent Command Center - Kill

Stop one or more agent sessions in the ACC tmux session.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **target**: Pane ID, window name, `--idle` (kill all idle agents), or `--all` (kill entire session)
- `--force` or `-f`: Skip confirmation

## Steps

1. **Resolve targets:**

   If `--all`:
   - Will destroy the entire `acc` tmux session
   - **IMPORTANT**: Ask for confirmation unless `--force` is passed

   If `--idle`:
   - Find all idle panes (same heuristics as /acc:status)
   - Kill only those panes

   If specific target:
   - Resolve by pane ID or window name

2. **Kill the targets:**

   For a specific pane:
   ```
   tmux kill-pane -t acc:{pane_id}
   ```

   For a window:
   ```
   tmux kill-window -t acc:{window_name}
   ```

   For the entire session:
   ```
   tmux kill-session -t acc
   ```

3. **Clean up any fullauto/watcher scripts:**
   ```
   # Kill any running watcher/fullauto processes
   pkill -f "acc-watcher.sh" 2>/dev/null
   pkill -f "acc-fullauto" 2>/dev/null
   rm -f /tmp/acc-watcher.sh /tmp/acc-fullauto-*.sh
   ```

4. **Report:**
   ```
   Killed: acc:{target}
   Remaining agents: X
   ```

## Examples

```
/acc:kill 0.1
```

```
/acc:kill api-refactor
```

```
/acc:kill --idle
```

```
/acc:kill --all --force
```
