---
description: Show taskflow command reference
---

Display the taskflow command reference:

**TaskFlow Commands** (all run in isolated agent context - zero main session tokens):

- `/tfs` - Quick status (task count, branch, tokens)
- `/tfl` - List all active tasks with status
- `/tfr TASK-ID` - Resume task (full context)
- `/tfc` - Compact ACTIVE.md (archive old notes)
- `/tfa` - Analyze token usage
- `/tfv` - Validate link integrity
- `/tfcap` - Capture session notes
- `/tfh` - Generate session handoff
- `/tfhelp` - Show this help

**Direct Scripts** (for terminal use):
```bash
~/.claude/skills/scripts/taskflow-status-minimal.sh  # Instant status
~/.claude/skills/scripts/taskflow-compact-active.sh  # Quick compact
~/.claude/skills/scripts/taskflow-resume.sh TASK-ID  # Resume task
```

All commands use the taskflow agent (subagent) to avoid polluting your main session context.