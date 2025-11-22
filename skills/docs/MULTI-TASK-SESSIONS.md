# Multi-Task Session Tracking

## The Problem (Before)

Old TaskFlow only tracked ONE task at a time:
- Work on TASK-001, TASK-002, TASK-003 in same session
- Run `/tfhandoff` → only TASK-003 saved
- Run `/tfresume` → only TASK-003 loaded
- **Lost context for TASK-001 and TASK-002!**

## The Solution (Now)

TaskFlow now tracks **ALL tasks in a session**:

### Session File: `.taskflow-session.json`

```json
{
  "session_id": "2025-11-21-1330",
  "started": "2025-11-21T13:30:00Z",
  "tasks": [
    {
      "id": "TASK-001",
      "started": "2025-11-21T13:30:00Z",
      "last_updated": "2025-11-21T14:15:00Z",
      "status": "in_progress"
    },
    {
      "id": "TASK-002",
      "started": "2025-11-21T14:20:00Z",
      "last_updated": "2025-11-21T15:00:00Z",
      "status": "completed"
    },
    {
      "id": "TASK-003",
      "started": "2025-11-21T15:05:00Z",
      "last_updated": "2025-11-21T15:30:00Z",
      "status": "in_progress"
    }
  ],
  "current_task": "TASK-003"
}
```

## Workflow

### 1. Start Working on Tasks

```bash
/tfstart TASK-001
# ... work on it ...

/tfstart TASK-002
# ... work on it ...

/tfstart TASK-003
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
#   - TASK-001 (in_progress) - last updated: 2025-11-21T14:15:00Z
#   - TASK-002 (completed) - last updated: 2025-11-21T15:00:00Z
#   - TASK-003 (in_progress) - last updated: 2025-11-21T15:30:00Z
# Current task: TASK-003
```

### 3. Sync All Session Tasks

```bash
/tfsync "Made progress on auth bug, fixed DB schema, started UI refactor"

# This updates ALL three task files:
# - docs/active/TASK-001.md
# - docs/active/TASK-002.md
# - docs/active/TASK-003.md
```

### 4. Create Handoff (End of Session)

```bash
/tfhandoff

# Output:
# ✓ Handoff saved: task-003-2025-11-21-1530
#   File: docs/handoff/task-003-2025-11-21-1530.md
#   Tasks: TASK-001 TASK-002 TASK-003
#
# Multiple tasks - choose one:
#   1) /tfstart TASK-001
#      → Fix authentication bug
#   2) /tfstart TASK-002
#      → Update database schema
#   3) /tfstart TASK-003
#      → Refactor UI components
```

### 5. Resume in New Session

```bash
/tfresume task-003-2025-11-21-1530

# Output:
# Tasks in this session (3):
#   1) TASK-001 - Fix authentication bug
#      Status: in_progress
#   2) TASK-002 - Update database schema
#      Status: completed
#   3) TASK-003 - Refactor UI components
#      Status: in_progress
#
# Which task do you want to resume?
# Enter number (1-3) or 'all' to see full handoff:
```

Choose a task:
```
2

# ✓ Now working on: TASK-002
# [Shows full task details from docs/active/TASK-002.md]
```

## Commands

| Command | What it does |
|---------|--------------|
| `/tfstart TASK-ID` | Start/resume task, adds to session |
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
