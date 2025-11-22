---
description: Name or rename current session (usage: /tfsname session-name)
---

Name or rename the current session for easy identification and crash recovery:

```bash
~/.claude/skills/scripts/taskflow-session.sh set-name {{args}}
```

Examples:
- `/tfsname perf-optimization` - Name session for performance work
- `/tfsname ui-fixes` - Name session for UI bug fixes
- `/tfsname cache-feature` - Name session for cache feature work

After naming, use `/tfs` to see your session name prominently displayed.
For crash recovery, use `/tfresume session-name` to restore your work.
