# What's New in TaskFlow

## Session Names for Crash Recovery (2025-11-21 LATEST)

### Problem Fixed

**Claude sessions freeze** - usually when pasting large content/images while near token limit. When this happens, you need to quickly recover your work, but session names were meaningless timestamps.

### Solution: Named Sessions

```bash
# Name your session early!
/tfsname cache-feature

# Status now shows session name prominently
/tfs
# 🔖 Session: cache-feature
# 📍 Current: PERF-009
# 📊 3 active tasks | main@abc1234 ✅

# When session crashes, resume by name:
/tfresume cache-feature
```

### Key Commands

- `/tfsname NAME` - Name/rename current session (use early!)
- `/tfs` - Status with session name displayed
- `/tfhandoff` - Save state, outputs ONE command to paste
- `/tfresume NAME` - Restore session after crash

### Crash Recovery Workflow

1. **Start work, name session immediately**:
   ```bash
   /tfstart PERF-009
   /tfsname perf-optimization
   ```

2. **Work continues** (session freezes at some point)

3. **Open new window, resume by name**:
   ```bash
   /tfresume perf-optimization
   ```

Done! No searching through timestamps.

### Session Naming Tips

✅ Good: `cache-feature`, `ui-fixes`, `perf-work`
❌ Bad: `work`, `session1`, `my-long-descriptive-session-name`

**Keep it short & descriptive** - you'll type it after crashes!

---

## Multi-Task Session Tracking (2025-11-21)

### Problem Fixed

**Before:** Working on 5-6 tasks in one session, running `/tfhandoff` only saved the LAST task you worked on. Lost context for all the others!

**Now:** TaskFlow tracks ALL tasks in a session and lets you choose which one to resume.

### What Changed

#### 1. Session Tracking (`.taskflow-session.json`)

Every time you `/tfstart TASK-ID`, it's added to the current session automatically.

Check what you've worked on:
```bash
/tfsession
```

#### 2. Multi-Task Handoffs

`/tfhandoff` now saves ALL session tasks:

```bash
/tfhandoff

# Output shows:
# Tasks: TASK-001 TASK-002 TASK-003
# Multiple tasks - choose one:
#   1) /tfstart TASK-001 → Fix auth bug
#   2) /tfstart TASK-002 → Update schema
#   3) /tfstart TASK-003 → Refactor UI
```

#### 3. Interactive Resume

`/tfresume SESSION-ID` presents task choices:

```bash
/tfresume task-003-2025-11-21-1530

# Shows all tasks, prompts:
# Which task do you want to resume?
# Enter number (1-3) or 'all':
```

Or skip straight to a task:
```bash
/tfresume task-003-2025-11-21-1530 2  # Resume task #2
```

#### 4. Smart /tfsync

`/tfsync` now updates ALL session tasks, not just current one:

```bash
/tfsync "Fixed login, updated DB schema, started UI work"

# Updates all three task files with relevant context
```

#### 5. New /tfstart Features

Create tasks on the fly:
```bash
/tfstart "Fix login bug"

# Searches for existing tasks with "login bug"
# If none found, creates TASK-NNN automatically
# Adds to ACTIVE.md
# Adds to session
```

### Commands Reference

| Command | Old Behavior | New Behavior |
|---------|-------------|--------------|
| `/tfstart ID` | Sets current task | Adds to session + sets current |
| `/tfstart "desc"` | ❌ Not supported | ✅ Search or create task |
| `/tfhandoff` | Saves 1 task | Saves ALL session tasks |
| `/tfresume ID` | Loads 1 task | Interactive task selection |
| `/tfsync` | Updates current | Updates ALL session tasks |
| `/tfsession` | ❌ New | Show session info |

### Files

**Created:**
- `.taskflow-session.json` - Session state (gitignored)
- `~/.claude/skills/scripts/taskflow-session.sh` - Session management
- `/tfsession` command

**Updated:**
- `/tfstart` - Session tracking + task creation
- `/tfhandoff` - Multi-task support
- `/tfresume` - Interactive selection
- `/tfsync` - Multi-task updates
- Taskflow agent - Session-aware instructions

**Documented:**
- `docs/MULTI-TASK-SESSIONS.md` - Full guide
- `docs/WHATS-NEW.md` - This file

### Migration

✅ **Zero migration required!**

- Works automatically on next `/tfstart`
- Compatible with old handoffs
- Falls back gracefully if jq not installed

### Example Workflow

```bash
# Work on multiple tasks
/tfstart PARQ-003
# ... fix parquet bug ...

/tfstart CAT-004
# ... update catalog ...

/tfstart ETL-001
# ... work on ETL pipeline ...

# Check what you've done
/tfsession
# Session ID: 2025-11-21-1330
# Tasks: PARQ-003, CAT-004, ETL-001

# Hitting token limit? Hand off work
/tfhandoff

# Output:
# ✓ Handoff saved: etl-001-2025-11-21-1530
#   Tasks: PARQ-003 CAT-004 ETL-001
#
# Multiple tasks - choose one:
#   1) /tfstart PARQ-003 → Fix WKB parsing bug
#   2) /tfstart CAT-004 → Update catalog schema
#   3) /tfstart ETL-001 → Optimize ETL pipeline

# Start new session, resume
/tfresume etl-001-2025-11-21-1530
# [Shows all 3 tasks, lets you pick]

# Choose task 2 (CAT-004)
2

# ✓ Now working on: CAT-004
# [Full task context loaded]
```

### Technical Notes

- Session file is **per-machine** (not synced via git)
- Handoff metadata **is synced** (in `docs/handoff/.sessions.json`)
- Session tracking requires `jq` (install via `brew install jq`)
- Graceful fallback to legacy single-task mode if jq unavailable

---

**Next:** Check out `/tfv2compare` to see the JSON prototype (79% token savings!)
