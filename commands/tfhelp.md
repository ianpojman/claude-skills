---
description: Show taskflow command reference
---

Display the taskflow command reference:

## 🚨 Crash Recovery Commands (memorize these!)

**Simple aliases** (use under stress):
- `/name session-name` - Name your session (do this early!)
- `/save` - Save session state before crash
- `/sessions` - List all saved sessions
- `/resume session-name` - Restore session after crash

**Recovery workflow:**
```
BEFORE: /name perf-work → /save
AFTER:  /sessions → /resume perf-work
```

---

## Complete Command Reference

**Session Management:**
- `/name NAME` or `/tfsname NAME` - Name/rename session
- `/save` or `/tfhandoff` - Save session, get resume command
- `/sessions` or `/tflist` - List saved sessions
- `/resume NAME` or `/tfresume NAME` - Resume session
- `/tfs` - Show status with session name

**Task Management:**
- `/tasks` or `/tfl` - List all active tasks
- `/tfstart TASK-ID` - Start task (creates Acceptance Criteria + Test Plan)
- `/tfstop` - Stop working on current task
- `/tfcurrent` - Show current task details
- `/tfsync` - Sync tasks to issue tracker

**Test Plan Workflow:**
Before closing any task, update the Test Plan table with actual results.
Tasks with `TODO` in Acceptance Criteria or incomplete tests cannot be closed.

**Maintenance:**
- `/tfcompact` - Compact ACTIVE.md (archive old notes)
- `/tfa` - Analyze token usage
- `/tfcap` - Capture session notes
- `/tfhelp` - Show this help

**Direct Scripts** (for terminal use):
```bash
~/.claude/skills/scripts/taskflow-status-minimal.sh  # Instant status
~/.claude/skills/scripts/taskflow-compact-active.sh  # Quick compact
~/.claude/skills/scripts/taskflow-resume.sh TASK-ID  # Resume task
```

All commands use the taskflow agent (subagent) to avoid polluting your main session context.