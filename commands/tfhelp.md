---
description: Show taskflow command reference
---

Display the taskflow command reference:

**Session Management** (for crash recovery & organization):

- `/tfsname NAME` - Name/rename current session (crucial for crash recovery!)
- `/tfs` - Show status with **session name** prominently
- `/tfhandoff` - Save session state, outputs resume command
- `/tfresume NAME` - Resume named session after crash

**Task Management**:

- `/tfstart TASK-ID` - Start working on a task
- `/tfstop` - Stop working on current task
- `/tfcurrent` - Show current task details
- `/tfl` - List all active tasks
- `/tfsync` - Sync tasks to issue tracker

**Maintenance**:

- `/tfcompact` - Compact ACTIVE.md (archive old notes)
- `/tfa` - Analyze token usage
- `/tfcap` - Capture session notes
- `/tfhelp` - Show this help

**Deprecated**:
- `/tfc` - Use `/tfsync` instead

**Direct Scripts** (for terminal use):
```bash
~/.claude/skills/scripts/taskflow-status-minimal.sh  # Instant status
~/.claude/skills/scripts/taskflow-compact-active.sh  # Quick compact
~/.claude/skills/scripts/taskflow-resume.sh TASK-ID  # Resume task
```

All commands use the taskflow agent (subagent) to avoid polluting your main session context.