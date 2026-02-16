---
description: Name current session (alias for /tfsname)
---

Name or rename the current session:

```bash
~/.claude/skills/scripts/taskflow-session.sh set-name {{args}}
```

Usage:
- `/name perf-work` - Name session "perf-work"
- `/name cache-feature` - Name session "cache-feature"

**Use this early in your session!** When Claude crashes, you'll resume by name:
```
/resume perf-work
```

This is a short alias for `/tfsname`.
