---
description: Launch a new Claude Code agent in a tmux pane
---

# Agent Command Center - Launch

Launch one or more new Claude Code agent sessions in the ACC tmux grid.

**Arguments:** `$ARGUMENTS`

Parse the arguments to determine:
- **task**: The task/prompt to give the agent (required)
- **count**: Number of agents to launch (default: 1, parse from `--count N` or `-n N`)
- **dir**: Working directory (default: current directory, parse from `--dir PATH` or `-d PATH`)
- **model**: Model to use (default: inherited, parse from `--model MODEL` or `-m MODEL`)
- **name**: Window name for the agent (parse from `--name NAME`)
- **dangerously-skip-permissions**: Whether to add the flag (parse from `--yolo` or `--auto-approve`)

## Steps

1. **Ensure tmux is available:**
   ```
   which tmux || echo "ERROR: tmux is not installed. Install with: brew install tmux"
   ```

2. **Create or attach to the ACC session:**
   ```
   tmux has-session -t acc 2>/dev/null || tmux new-session -d -s acc -x 220 -y 50
   ```

3. **For each agent to launch**, create a new pane:

   If this is the first pane in the session and it's empty, use it. Otherwise split or create a new window:
   ```
   # Create a new window for the agent
   tmux new-window -t acc -n "{name}"
   ```

   Or to add to an existing window as a split:
   ```
   tmux split-window -t acc -h  # horizontal split
   ```

4. **Send the claude command to the pane:**
   ```
   tmux send-keys -t acc:{window} "cd {dir} && claude {model_flag} {permissions_flag} \"{task}\"" Enter
   ```

   Where:
   - `{model_flag}` is `--model {model}` if specified, empty otherwise
   - `{permissions_flag}` is `--dangerously-skip-permissions` if `--yolo` was passed
   - `{task}` is the task prompt (properly escaped for shell)

5. **Report what was launched:**
   ```
   Agent launched in acc:{window}.{pane}
   Task: {task}
   Directory: {dir}
   ```

## Examples

Single agent:
```
/acc:launch Fix the authentication bug in src/auth.ts
```

Multiple agents with options:
```
/acc:launch --count 3 --dir ./backend --name api-refactor Refactor the API endpoints to use async/await
```

Full auto mode:
```
/acc:launch --yolo Write comprehensive tests for the utils module
```

After launching, suggest the user run `/acc:status` to see their agent grid or `/acc:dashboard` for the full overview.
