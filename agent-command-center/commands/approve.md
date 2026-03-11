---
description: Approve a blocked agent's pending action
---

# Agent Command Center - Approve

Send approval to a blocked agent that's waiting for permission confirmation.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **target**: Pane ID, window name, or `--all` to approve all blocked agents
- `--reject` or `-r`: Send rejection instead of approval

## Steps

1. **Find blocked agents:**
   ```
   tmux list-panes -a -t acc -F '#{window_index}.#{pane_index}|#{window_name}'
   ```

   For each pane, check if blocked:
   ```
   tmux capture-pane -t acc:{pane} -p -S -10
   ```

   Look for approval indicators: "Allow", "Do you want to proceed", "Y/n", "approve"

2. **If a specific target was given**, verify it's actually blocked before sending approval.

3. **Send the response:**

   For approval:
   ```
   tmux send-keys -t acc:{pane} "y" Enter
   ```

   For rejection:
   ```
   tmux send-keys -t acc:{pane} "n" Enter
   ```

4. **Report:**
   ```
   Approved: acc:{pane} ({window_name})
   Action: {brief description of what was being asked}
   ```

   Or if `--all`:
   ```
   Approved X blocked agent(s):
   - acc:1.1 (docs) - Write to docs/api.md
   - acc:2.0 (deploy) - Run deploy script
   ```

**IMPORTANT**: Warn the user before approving if the blocked action seems destructive (delete, force push, rm -rf, etc.). In that case, show what's being asked and confirm with the user first.

## Examples

```
/acc:approve 1.1
```

```
/acc:approve --all
```

```
/acc:approve docs --reject
```
