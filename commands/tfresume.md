---
description: Resume from a session handoff (usage: /tfresume SESSION-ID [task-num])
---

Resume from a saved session handoff with task selection:

```bash
~/.claude/skills/scripts/taskflow-resume-session.sh {{args}}
```

Usage:
- `/tfresume SESSION-ID` - Interactive: shows all tasks, lets you choose
- `/tfresume SESSION-ID 2` - Direct: resume task #2 from that session
