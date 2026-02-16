---
description: List all saved sessions (alias for /tflist)
---

List all saved session handoffs:

```bash
~/.claude/skills/scripts/taskflow-list-sessions.sh
```

Shows all sessions you've saved with `/save` or `/tfhandoff`.

Use this after a crash to find which session to resume:
```
/sessions
# Shows: perf-work, ui-fixes, cache-feature
/resume perf-work
```

This is a short alias for `/tflist`.
