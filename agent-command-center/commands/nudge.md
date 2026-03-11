---
description: Send a prompt to idle agents to get them working again
---

# Agent Command Center - Nudge

Send a prompt to one or more idle agents to re-engage them.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **target**: Specific pane ID, window name, or `--all` for all idle agents (default: `--all`)
- **message**: Custom nudge message (default: "Continue working on your task.")

## Steps

1. **Find idle agents:**
   ```
   tmux list-panes -a -t acc -F '#{window_index}.#{pane_index}|#{window_name}'
   ```

   For each pane, check if idle by capturing last 5 lines:
   ```
   tmux capture-pane -t acc:{pane} -p -S -5
   ```

   An agent is idle if it does NOT show active indicators ("esc to interrupt", "Thinking", etc.) and DOES show prompt indicators (">", "$", "claude>") or completion phrases.

2. **Send the nudge:**

   For each targeted idle agent:
   ```
   tmux send-keys -t acc:{pane} "{message}" Enter
   ```

3. **Report results:**
   ```
   Nudged X idle agent(s):
   - acc:0.1 (test-writer) <- "Continue working on your task."
   - acc:1.0 (bug-fix) <- "Continue working on your task."

   Skipped X active agent(s).
   ```

   If no idle agents found:
   ```
   All agents are currently active. No nudging needed.
   ```

## Examples

```
/acc:nudge
```

```
/acc:nudge 0.1 Focus on edge cases in the test suite
```

```
/acc:nudge --all Prioritize error handling, this is critical
```
