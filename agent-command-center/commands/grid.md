---
description: Arrange agent panes in a tiled grid layout
---

# Agent Command Center - Grid

Rearrange all agent panes into a clean tiled grid layout for easy visual monitoring.

**Arguments:** `$ARGUMENTS`

Parse options:
- **layout**: `tiled` (default), `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`
- `--per-window N`: Maximum panes per window before creating a new window (default: 4)

## Steps

1. **Get current pane layout:**
   ```
   tmux list-windows -t acc -F '#{window_index}:#{window_name} (#{window_panes} panes)'
   tmux list-panes -a -t acc -F '#{window_index}.#{pane_index}'
   ```

2. **Apply the layout to each window:**
   ```
   for win in $(tmux list-windows -t acc -F '#{window_index}'); do
     tmux select-layout -t "acc:${win}" {layout}
   done
   ```

3. **If `--per-window` was specified and any window has too many panes**, redistribute:
   - Count panes per window
   - If over limit, break excess panes into new windows
   - Re-apply layout to all windows

4. **Synchronize pane sizes** for a clean grid:
   ```
   tmux set-window-option -t acc synchronize-panes off
   ```

5. **Report the new layout:**
   ```
   Grid layout applied: {layout}
   Windows: X, Total panes: Y
   ```

## Examples

```
/acc:grid
```

```
/acc:grid even-horizontal
```

```
/acc:grid --per-window 6 tiled
```
