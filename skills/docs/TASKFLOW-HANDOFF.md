# TaskFlow Handoff - Auto-Capture & Task Creation

## Overview

The `/tfhandoff` command now **automatically captures session state and creates task records** for any new tasks identified during the session.

## Key Features

### 1. Auto-Capture
When you provide a summary, handoff automatically saves it to ACTIVE.md:
```bash
/tfhandoff my-session "Fixed auth bug, deployed v2.0"
```
This runs `taskflow capture` behind the scenes before creating the handoff.

### 2. Auto-Create Task Files
Handoff ensures **all tasks in the session have proper task files**:
- Scans `.taskflow-session.json` for all tasks worked on
- Creates `docs/active/TASK-ID.md` for any missing tasks
- Adds missing tasks to `ACTIVE.md` index
- Extracts task titles from ACTIVE.md when available

### 3. Complete Session Documentation
The handoff includes:
- All tasks worked on (not just current one)
- Git status and branch info
- Running processes (EMR clusters, etc.)
- Recent session notes from ACTIVE.md
- Resume command for next session

## Usage

### Basic Handoff
```bash
/tfhandoff
```
Auto-generates name like `TASK-003-2025-11-21-1430`

### Named Handoff
```bash
/tfhandoff auth-fix
```
Creates `docs/handoff/auth-fix.md`

### Handoff with Capture
```bash
/tfhandoff auth-fix "Fixed OAuth bug, all tests passing"
```
1. Captures summary to ACTIVE.md
2. Creates task files for new tasks
3. Generates handoff document

## What Gets Auto-Created

When handoff finds tasks in `.taskflow-session.json` without task files:

**Creates:** `docs/active/TASK-ID.md`
```markdown
# TASK-ID: Task Title

**Status**: in_progress
**Created**: 2025-11-21 14:30
**Auto-generated**: Created during handoff

## Description

Task Title (extracted from ACTIVE.md)

## Tasks

- [ ] TODO (add details)

## Notes

(Auto-created during session handoff)
```

**Updates:** `ACTIVE.md`
```markdown
## 🚀 Active Tasks

### TASK-ID: Task Title
[Details →](docs/active/TASK-ID.md)
```

## Benefits

### Before (Manual Workflow)
```bash
# User had to manually:
/tfc "session notes"                    # Capture
# Create task files by hand
# Update ACTIVE.md manually
/tfhandoff my-session                   # Then handoff
```

### After (Automatic Workflow)
```bash
# Single command does everything:
/tfhandoff my-session "session notes"
```

### Prevents Lost Tasks
If you worked on multiple tasks but forgot to create task files:
- Old behavior: Tasks tracked in session but no documentation
- New behavior: Handoff auto-creates task files with basic structure

## Example Session Flow

```bash
# Start working
/tfstart PERF-009

# During work, switch to another task
# (Manually add to session or agent tracks it)
~/.claude/skills/scripts/taskflow-session.sh add BUG-042

# End of session - handoff auto-creates BUG-042.md if missing
/tfhandoff perf-session "Fixed PERF-009, discovered BUG-042 in auth"
```

Output:
```
📝 Captured session state to ACTIVE.md
⚠️  Creating missing task file: BUG-042
   ✓ Created: docs/active/BUG-042.md
   ✓ Added to ACTIVE.md

✅ Session handoff saved
📄 Details saved to: docs/handoff/perf-session.md
📋 Tasks: PERF-009 BUG-042

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 To resume in a new session, paste this:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /tfresume perf-session
```

## Implementation Details

### Script: `taskflow-handoff.sh`

**Step 1: Auto-Capture** (if summary provided)
```bash
if [ -n "$CAPTURE_SUMMARY" ]; then
    taskflow-capture.sh "$CAPTURE_SUMMARY"
fi
```

**Step 2: Get Session Tasks**
```bash
mapfile -t ALL_TASKS < <(taskflow-session.sh get-all)
```

**Step 3: Create Missing Task Files**
```bash
for TASK_ID in "${ALL_TASKS[@]}"; do
    if [ ! -f "docs/active/${TASK_ID}.md" ]; then
        # Extract title from ACTIVE.md
        # Create task file
        # Add to ACTIVE.md if missing
    fi
done
```

**Step 4: Generate Handoff Document**
- All tasks with status and details
- Git status, running processes
- Resume command

## Related Commands

- `/tfs` - Show status with current task
- `/tfl` - List all active tasks
- `/tfr TASK-ID` - Resume specific task
- `/tfresume session-name` - Resume entire session
- `/tfsync` - Sync tasks to issue tracker

## See Also

- `~/.claude/agents/taskflow.md` - Full TaskFlow documentation
- `~/.claude/skills/docs/MULTI-TASK-SESSIONS.md` - Session tracking details
- `~/.claude/skills/docs/TASKFLOW-WORKING-DIRECTORY.md` - Directory awareness guide
