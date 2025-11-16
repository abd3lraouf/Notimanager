# Squad Management System - Quick Reference

A flat multi-agent system for parallel task execution with 1 Squad Manager → 10 Agents.

## Command Structure

```
/
├── squad-manager.md    # Top-level orchestrator (10 agents)
├── agent.md            # Worker execution unit
├── squad-status.md     # Monitoring dashboard
├── team-lead.md        # DEPRECATED - No longer used
└── SQUAD-README.md     # This file
```

## Quick Start

### For Squad Manager (You)
```
1. User: "Analyze this codebase"
2. You: Parse mission → Launch 10 agents in background
3. Monitor: Check status every 30 seconds
4. Coordinate: Handle issues, redistribute work
5. Complete: Aggregate results → Present to user
```

### For Agent
```
1. Receive task from Squad Manager
2. Execute with appropriate tools
3. Report progress every 60-90 seconds
4. Escalate blockers immediately
5. Deliver complete, quality output
```

## Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                    SQUAD MANAGER                        │
│  • Launches 10 Agents directly                          │
│  • Monitors all activity                                │
│  • Coordinates between agents                           │
│  • Reports to user                                     │
└────────────────┬────────────────────────────────────────┘
                 │
    ┌────────────┼────────────┬────────┬────────┬────────┐
    │            │            │        │        │        │
┌───▼───┐ ┌────▼───┐ ┌────▼───┐▼──┬───┐ ┌──▼───┐ ┌──▼───┐
│Agent 01│ │Agent 02│ │Agent 03│  Agent 04-10...     │
└───────┘ └────────┘ └────────┘       │              │
                                         │              │
                                   All agents report
                                   directly to Squad
                                   Manager
```

## Monitoring Commands

| Command | Purpose |
|---------|---------|
| `/squad-manager` | Launch squad manager for complex tasks |
| `/squad-status` | Show full dashboard |
| `/squad-status 05` | Show specific agent (01-10) |
| `/squad-status --alerts` | Show issues only |
| `/squad-status --metrics` | Show performance metrics |

## Status Indicators

| Symbol | Meaning |
|--------|---------|
| 🔄 | Processing/Active |
| ✅ | Complete |
| ⏳ | Waiting/Queued |
| ⚠️ | Warning (minor issue) |
| ❌ | Failed/Blocked |
| 🔁 | Relaunching |

## Typical Workflow

### Phase 1: Mission Assignment (0-1 min)
```
User → Squad Manager
      "Analyze Notimanager codebase"
```

### Phase 2: Squad Launch (1-2 min)
```
Squad Manager → Launch 10 agents in parallel
```

### Phase 3: Agent Execution (2-15 min)
```
All 10 agents working in parallel on different aspects
```

### Phase 4: Results Aggregation (15-20 min)
```
Squad Manager collects all agent results
```

### Phase 5: Final Report (20 min)
```
Squad Manager → User
                 "Mission complete! Summary..."
```

## Performance Expectations

| Metric | Target |
|--------|--------|
| Agent startup | < 30 seconds |
| First progress report | < 60 seconds |
| Task completion | 2-10 minutes |
| Squad efficiency | > 85% |
| Parallel utilization | 10 agents concurrent |

## Troubleshooting

### Agent Not Responding
1. Squad Manager: Check via TaskOutput
2. If no output > 90s: Relaunch
3. If fails twice: Redistribute work

### Multiple Agent Failures
1. Squad Manager: Check all agent status
2. Identify common failure patterns
3. Adjust approach and relaunch

### Squad Deadlock
1. Squad Manager: Pause operations
2. Identify root cause
3. Reset and relaunch affected agents

## Best Practices

### For Squad Manager
- ✅ Launch agents in background (never wait)
- ✅ Check status frequently (30-45s)
- ✅ Communicate proactively to user
- ✅ Handle failures gracefully
- ✅ Balance workload across agents
- ❌ Never do work yourself (delegate)
- ❌ Don't wait until end to report

### For Agents
- ✅ Report progress frequently
- ✅ Escalate blockers early
- ✅ Deliver quality work
- ✅ Follow instructions precisely
- ✅ Work independently
- ❌ Don't go silent
- ❌ Don't work outside assigned scope

## File Locations

```
.claude/commands/
├── squad-manager.md    # Main orchestrator (10 agents)
├── agent.md            # Worker unit
├── squad-status.md     # Monitor/dashboard
├── team-lead.md        # DEPRECATED
└── SQUAD-README.md     # This guide
```

## Usage Examples

### Example 1: Code Analysis
```
User: /squad-manager Analyze NotificationMover.swift for bugs

Manager:
  🎯 MISSION: Bug analysis of NotificationMover.swift
  📋 STRATEGY: 10 parallel analysis tracks
  ⏳ Launching 10 agents...
```

### Example 2: Feature Implementation
```
User: /squad-manager Implement dark mode for settings window

Manager:
  🎯 MISSION: Dark mode implementation
  📋 STRATEGY: 10 parallel implementation tracks
  ⏳ Launching 10 agents...
```

### Example 3: Documentation
```
User: /squad-manager Document the entire codebase

Manager:
  🎯 MISSION: Comprehensive documentation
  📋 STRATEGY: 10 parallel documentation tracks
  ⏳ Launching 10 agents...
```

## Integration with Claude Code

This system integrates with Claude Code's built-in Task tool:

```swift
// Launch agent
Task(
  subagent_type: "general-purpose",
  prompt: "<agent instructions>",
  description: "Agent 01 - Mission",
  run_in_background: true
)

// Monitor agent
TaskOutput(
  task_id: "<returned_task_id>",
  block: false,
  timeout: 5000
)
```

## Advanced Features

### Dynamic Rebalancing
Squad Manager can redistribute work between agents based on completion speed.

### Cascading Failures
If multiple agents fail, Squad Manager can adjust strategy and relaunch.

### Progress Persistence
Session state saved every 30 seconds for recovery.

### Multi-Mission Support
Squad can handle 2-3 missions simultaneously with proper tagging.

## Limitations

- Maximum 10 concurrent agents
- Agents must be general-purpose type
- Background execution required for parallelism
- Squad Manager directly coordinates all agents

## Future Enhancements

- [ ] Support for 15-20 agents
- [ ] Specialized agent types (code, research, testing)
- [ ] Persistent squad that stays running
- [ ] Inter-agent communication channels
- [ ] Learned optimization from past missions

## Support

For issues or questions:
1. Check `/squad-status` first
2. Review command documentation
3. Escalate to Squad Manager

---

**Remember:** The strength of the squad is in parallel execution and clear communication. The flat structure reduces latency and improves coordination!
