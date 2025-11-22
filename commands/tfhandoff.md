---
description: Create session handoff (usage: /tfhandoff [name] ["summary"])
---

Create a named session handoff. Automatically captures session state and creates task files for any new tasks.

Usage:
- `/tfhandoff` - Auto-named handoff
- `/tfhandoff my-session` - Named handoff
- `/tfhandoff my-session "Fixed bug, deployed to prod"` - Named with capture summary

The handoff will:
1. Capture session summary to ACTIVE.md (if summary provided)
2. Create task files for any tasks missing them
3. Generate handoff document with all session tasks
4. Save resume command for next session

```bash
~/.claude/skills/scripts/taskflow-handoff.sh {{args}}
```
