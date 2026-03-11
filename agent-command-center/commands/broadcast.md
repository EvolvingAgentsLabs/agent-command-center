---
description: Send a message to all or selected agents simultaneously
---

# Agent Command Center - Broadcast

Send the same prompt/instruction to multiple agents at once.

**Arguments:** `$ARGUMENTS`

Parse arguments:
- **message**: The message to broadcast (required - everything after options)
- `--active`: Only send to active agents
- `--idle`: Only send to idle agents (default if no filter specified)
- `--all`: Send to ALL agents regardless of status
- `--filter PATTERN`: Only send to agents whose window name matches the pattern

## Steps

1. **Get all agent panes and their statuses** (same detection as /acc:status)

2. **Filter based on options:**
   - Default (no filter): only idle agents
   - `--active`: only active agents (will interrupt them)
   - `--idle`: only idle agents
   - `--all`: every agent
   - `--filter`: name matching

3. **If sending to active agents, WARN the user** that this will interrupt their current work and ask for confirmation.

4. **Send the message to each target:**
   ```
   tmux send-keys -t acc:{pane} "{message}" Enter
   ```

5. **Report:**
   ```
   Broadcast sent to X agent(s):
   - acc:0.0 (api-refactor) [IDLE]
   - acc:0.1 (test-writer) [IDLE]
   - acc:1.0 (bug-fix) [IDLE]

   Message: "{message}"
   ```

## Examples

```
/acc:broadcast Wrap up your current task and commit your changes
```

```
/acc:broadcast --all PRIORITY SHIFT: Stop current work and focus on fixing the production bug in auth.ts
```

```
/acc:broadcast --filter test Add coverage for error edge cases
```
