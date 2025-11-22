---
description: Compact ACTIVE.md (archive old session notes and completed tasks)
---

Run the taskflow compact script:

```bash
~/.claude/skills/scripts/taskflow-compact-active.sh
```

This script performs two operations:
1. **Archives old session notes** (>3 days) to `docs/session-notes/`
2. **Detects completed tasks** in `docs/active/` and moves them to `docs/completed/YYYY-MM-DD/`

Completed task detection looks for status markers like:
- `Status: ✅ COMPLETE`
- `Status: ✅ VALIDATED`
- `Status: ✅ FIXED`
- `Status: ✅ DONE`

**Note**: After running, you'll need to manually update ACTIVE.md to remove archived tasks from the Active Tasks section and add them to Recently Completed.
