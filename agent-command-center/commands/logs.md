---
description: View the recent output/logs from an agent pane
---

# Agent Command Center - Logs

Capture and display the recent output from one or more agent panes.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **target**: Pane ID or window name (required, or `--all` for all panes)
- `--lines N` or `-n N`: Number of lines to capture (default: 50)
- `--follow` or `-f`: Suggest how to follow output in real-time

## Steps

1. **Resolve target pane(s):**
   ```
   tmux list-panes -a -t acc -F '#{window_index}.#{pane_index}|#{window_name}'
   ```

2. **Capture output:**
   ```
   tmux capture-pane -t acc:{pane} -p -S -{lines}
   ```

3. **Display with header:**
   ```
   ═══ Agent: {window_name} (acc:{pane_id}) ═══
   {captured output}
   ═══════════════════════════════════════════
   ```

4. If `--follow` was requested, suggest:
   ```
   To follow this agent's output in real-time:
   tmux attach -t acc:{pane_id}
   (Press Ctrl+B then D to detach back)
   ```

5. If `--all`, show each pane's output separated by headers.

## Examples

```
/acc:logs 0.0
```

```
/acc:logs api-refactor --lines 100
```

```
/acc:logs --all -n 20
```
