---
description: Sync ALL session tasks to issue tracker (create/update)
---

Sync ALL tasks worked on in this session to the issue tracking system.

**NEW: Multi-task aware!** This command now:
- Detects ALL tasks worked on in the current session (not just current task)
- Updates each task file in `docs/active/TASK-ID.md` with progress
- Uses conversation context, todos, git changes to infer updates
- Creates new task files if needed

Usage:
- `/tfsync` - Auto-detect all session work and update all task files
- `/tfsync "progress update"` - Update all session tasks with provided context
- `/tfsync new "Task title"` - Create a new issue

Session tracking via `.taskflow-session.json` - see `/tfsession` for details.

Invoke the taskflow agent to handle this:

```
Use Task tool with subagent_type="taskflow" and prompt="sync: [user's input]. IMPORTANT: Check .taskflow-session.json to get ALL tasks worked on in this session, not just current task. Update all of them."
```
