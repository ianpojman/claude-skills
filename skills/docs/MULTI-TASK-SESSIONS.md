# Multi-Task Session Tracking

## The Problem (Before)

Old TaskFlow only tracked ONE task at a time:
- Work on AUTH-001, DB-002, UI-003 in same session
- Run `/tfhandoff` → only UI-003 saved
- Run `/tfresume` → only UI-003 loaded
- **Lost context for AUTH-001 and DB-002!**

## The Solution (Now)

TaskFlow now tracks **ALL tasks in a session**:

### Session File: `.taskflow-session.json`

```json
{
  "session_id": "2025-11-21-1330",
  "started": "2025-11-21T13:30:00Z",
  "tasks": [
    {
      "id": "AUTH-001",
      "started": "2025-11-21T13:30:00Z",
      "last_updated": "2025-11-21T14:15:00Z",
      "status": "in_progress"
    },
    {
      "id": "DB-002",
      "started": "2025-11-21T14:20:00Z",
      "last_updated": "2025-11-21T15:00:00Z",
      "status": "completed"
    },
    {
      "id": "UI-003",
      "started": "2025-11-21T15:05:00Z",
      "last_updated": "2025-11-21T15:30:00Z",
      "status": "in_progress"
    }
  ],
  "current_task": "UI-003"
}
```

## Workflow

### 1. Start Working on Tasks

```bash
/tfstart AUTH-001 "Fix authentication bug"
# ... work on it ...

/tfstart DB-002 "Update database schema"
# ... work on it ...

/tfstart UI-003 "Refactor UI components"
# ... work on it ...
```

**Behind the scenes:** Each `/tfstart` adds the task to `.taskflow-session.json`

### 2. Check Session Status

```bash
/tfsession

# Output:
# Session ID: 2025-11-21-1330
# Started: 2025-11-21T13:30:00Z
# Tasks worked on:
#   - AUTH-001 (in_progress) - last updated: 2025-11-21T14:15:00Z
#   - DB-002 (completed) - last updated: 2025-11-21T15:00:00Z
#   - UI-003 (in_progress) - last updated: 2025-11-21T15:30:00Z
# Current task: UI-003
```

### 3. Sync All Session Tasks

```bash
/tfsync "Made progress on auth bug, fixed DB schema, started UI refactor"

# This updates ALL three task files:
# - docs/active/AUTH-001.md
# - docs/active/DB-002.md
# - docs/active/UI-003.md
```

### 4. Create Handoff (End of Session)

```bash
/tfhandoff

# Output:
# ✓ Handoff saved: ui-003-2025-11-21-1530
#   File: docs/handoff/ui-003-2025-11-21-1530.md
#   Tasks: AUTH-001 DB-002 UI-003
#
# Multiple tasks - choose one:
#   1) /tfstart AUTH-001
#      → Fix authentication bug
#   2) /tfstart DB-002
#      → Update database schema
#   3) /tfstart UI-003
#      → Refactor UI components
```

### 5. Resume in New Session

```bash
/tfresume task-003-2025-11-21-1530

# Output:
# Tasks in this session (3):
#   1) AUTH-001 - Fix authentication bug
#      Status: in_progress
#   2) DB-002 - Update database schema
#      Status: completed
#   3) UI-003 - Refactor UI components
#      Status: in_progress
#
# Which task do you want to resume?
# Enter number (1-3) or 'all' to see full handoff:
```

Choose a task:
```
2

# ✓ Now working on: DB-002
# [Shows full task details from docs/active/DB-002.md]
```

## Commands

| Command | What it does |
|---------|--------------|
| `/tfstart ISSUE-ID` | Start/resume task, adds to session |
| `/tfstart ISSUE-ID "desc"` | Create new task with custom ID |
| `/tfsession` | Show all tasks in current session |
| `/tfsync` | Update ALL session task files |
| `/tfhandoff` | Save handoff with ALL session tasks |
| `/tfresume SESSION-ID` | Resume with task choice |
| `/tfresume SESSION-ID 2` | Resume task #2 directly |

## Benefits

✅ **Never lose context** - All tasks tracked automatically
✅ **Smart handoffs** - Present task choices on resume
✅ **Accurate sync** - `/tfsync` updates all relevant tasks
✅ **Better history** - Session metadata tracks what you worked on when

## Technical Details

- **Session file**: `.taskflow-session.json` (gitignored, per-machine)
- **Legacy compat**: `.taskflow-current` still works (single task)
- **Session script**: `~/.claude/skills/scripts/taskflow-session.sh`
- **Handoff metadata**: `docs/handoff/.sessions.json` (tracked in git)

## Migration

No migration needed! The new system:
- Auto-creates session file on first `/tfstart`
- Falls back to legacy mode if session script missing
- Works alongside old handoffs

Just start using it naturally.
