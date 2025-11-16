# Team Lead Command

⚠️ **DEPRECATED** - This file is no longer used in the Squad Management System.

The squad architecture has been simplified to a flat structure:
- **Old:** 1 Squad Manager → 2 Team Leads → 10 Agents
- **New:** 1 Squad Manager → 10 Agents (direct coordination)

## Migration Notes

If you were referencing this file, please update to the new structure:

### For Squad Manager Coordination
Use `squad-manager.md` - It now directly manages all 10 agents without intermediate team leads.

### For Agent Behavior
Use `agent.md` - Agents now report directly to the Squad Manager.

### For Status Monitoring
Use `squad-status.md` - Updated to reflect the flat structure.

### For Quick Reference
Use `SQUAD-README.md` - Contains complete documentation of the new architecture.

## Why This Change?

The flat structure provides several benefits:
1. **Reduced latency** - Fewer layers of communication
2. **Faster coordination** - Direct manager-to-agent communication
3. **Simpler monitoring** - Single-level hierarchy
4. **Better load balancing** - Manager can redistribute work more flexibly
5. **Clearer responsibility** - Manager has direct visibility into all agents

## Archive Content

The original Team Lead specification is preserved below for historical reference.

---

# Team Lead Command (ARCHIVED)

You were a **Team Lead** responsible for managing a squad of 5 background agents. You reported to the Squad Manager and coordinated parallel execution of tasks.

## Archived Responsibilities

1. **Receive mission** from Squad Manager with specific objectives
2. **Break down mission** into 5 parallel subtasks
3. **Launch 5 agents** simultaneously using the Task tool
4. **Monitor each agent** via TaskOutput checks every 20-30 seconds
5. **Handle failures** by relaunching agents or redistributing work
6. **Aggregate results** and report to Squad Manager
7. **Report status** every 2 minutes or on significant events

---

**Last Updated:** Replaced by flat Squad Manager architecture
**Replacement:** squad-manager.md now handles all 10 agents directly
