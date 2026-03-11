# Agent Command Center (ACC)

**A Claude Code plugin for managing teams of parallel AI agents via tmux.**

For the full documentation with architecture diagrams, installation tutorial, use cases, and command reference, see the [main README](../README.md).

## Quick Install

```
/plugin marketplace add EvolvingAgentsLabs/agent-command-center
/plugin install acc@EvolvingAgentsLabs-agent-command-center
```

## Quick Start

```
/acc:launch --name backend Fix all error handling in the API routes
/acc:launch --name tests Write unit tests for the auth module
/acc:status
/acc:watch
/acc:dashboard
```

## Commands

| Command | Description |
|:---|:---|
| `/acc:launch` | Start a new agent in a tmux pane |
| `/acc:status` | Show status of all agents |
| `/acc:dashboard` | Rich dashboard with stats |
| `/acc:watch` | Auto-prompt idle agents |
| `/acc:fullauto` | Aggressive auto-continue mode |
| `/acc:nudge` | One-shot re-prompt idle agents |
| `/acc:broadcast` | Message multiple agents |
| `/acc:approve` | Approve blocked agents |
| `/acc:logs` | View agent output |
| `/acc:grid` | Rearrange pane layout |
| `/acc:kill` | Stop agents and clean up |

## License

MIT
