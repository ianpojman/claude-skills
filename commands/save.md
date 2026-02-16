---
description: Save session state (alias for /tfhandoff)
---

Save current session state and get resume command:

```bash
~/.claude/skills/scripts/taskflow-handoff.sh {{args}}
```

Usage:
- `/save` - Save current session with auto-generated name
- `/save my-session` - Save with custom name

This is a short alias for `/tfhandoff` - use it when Claude is about to freeze!

After saving, you'll get ONE command to paste:
```
/resume my-session
```
