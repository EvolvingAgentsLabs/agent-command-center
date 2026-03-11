---
name: agent-monitor
description: Monitors and manages parallel Claude Code agent sessions running in tmux. Use this skill when the user mentions managing agents, checking agent status, working with tmux panes, or coordinating multi-agent workflows.
---

# Agent Monitor Skill

You have access to the Agent Command Center (ACC), a system for managing parallel Claude Code agents via tmux.

## Architecture

- All agents run in a tmux session named `acc`
- Each agent is a Claude Code instance running in a separate tmux pane
- Agents are identified by their `window_index.pane_index` (e.g., `0.0`, `1.2`) or window name

## Agent Status Detection

To determine an agent's status, capture its recent output with:
```
tmux capture-pane -t acc:{window}.{pane} -p -S -5
```

Status classification:
- **ACTIVE**: Output contains "esc to interrupt", "Thinking", "Reading", "Writing", "Editing", "Searching", or "Running"
- **IDLE**: Output shows prompt (`>`, `$`, `claude>`, `%`) or completion phrases ("What would you like", "How can I help")
- **BLOCKED**: Output shows approval prompts ("Allow?", "Do you want to proceed?", "Y/n")
- **ERRORED**: Output contains error messages, stack traces, or "Error:"
- **COMPLETED**: Shell prompt visible after claude process exited

## Available Commands

Direct the user to these ACC commands:
- `/acc:launch` - Start new agents
- `/acc:status` - Quick status overview
- `/acc:dashboard` - Rich dashboard with stats
- `/acc:watch` - Auto-prompt idle agents
- `/acc:fullauto` - Aggressive auto-continue mode
- `/acc:nudge` - Re-prompt idle agents once
- `/acc:kill` - Stop agents
- `/acc:grid` - Rearrange pane layout
- `/acc:approve` - Approve blocked agents
- `/acc:logs` - View agent output
- `/acc:broadcast` - Message multiple agents

## Proactive Monitoring

When asked about agent status or when managing multiple agents, proactively:
1. Check if any agents are idle and suggest nudging them
2. Check if any agents are blocked and alert the user
3. Report on overall progress across all agents
4. Suggest layout adjustments if there are many panes
