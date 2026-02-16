# TaskFlow Compatibility Fix

## Issues Fixed

### 1. `mapfile` Compatibility Error
**Error**: `mapfile: command not found`

**Root Cause**:
- The `mapfile` builtin was introduced in Bash 4.0
- macOS ships with Bash 3.2 by default
- Line 35 in `taskflow-handoff.sh` used `mapfile -t ALL_TASKS < <(...)`

**Fix**:
Replaced with portable alternative that works on Bash 3.2+:
```bash
# Old (Bash 4+ only):
mapfile -t ALL_TASKS < <("$SESSION_SCRIPT" get-all)

# New (Bash 3.2+ compatible):
while IFS= read -r task; do
    [ -n "$task" ] && ALL_TASKS+=("$task")
done < <("$SESSION_SCRIPT" get-all)
```

### 2. Mixed Task Format jq Error
**Error**: `jq: error: Cannot index string with string "id"`

**Root Cause**:
- `.taskflow-session.json` had mixed task formats:
  - Some tasks as strings: `"TASK-001"`, `"CI-BUILD"`
  - Some tasks as objects: `{"id": "PERF-010", "started": "...", ...}`
- jq query `.tasks[].id` worked for objects but failed for strings

**Example Problematic JSON**:
```json
{
  "tasks": [
    "TASK-001",           // String format
    "CI-BUILD",           // String format
    {                     // Object format
      "id": "PERF-010",
      "started": "2025-11-22T00:25:32Z",
      "status": "in_progress"
    }
  ]
}
```

**Fix**:
Updated jq queries in `taskflow-session.sh` to handle both formats:

```bash
# get_all_tasks() - now handles both formats:
jq -r '.tasks[] | if type == "string" then . else .id end' "$SESSION_FILE"

# get_session_info() - displays both formats appropriately:
jq -r '.tasks[] | if type == "string" then "  - \(.)" else "  - \(.id) (\(.status)) - last updated: \(.last_updated)" end' "$SESSION_FILE"

# add_task() - checks for existing tasks in either format:
jq -r ".tasks[] | if type == \"string\" then . else .id end | select(. == \"$TASK_ID\")" "$SESSION_FILE"
```

## Files Modified

1. **~/.claude/skills/scripts/taskflow-handoff.sh**
   - Line 35-38: Replaced `mapfile` with portable `while read` loop

2. **~/.claude/skills/scripts/taskflow-session.sh**
   - Line 68: Updated `add_task()` to check both formats
   - Line 73-74: Updated task update logic to handle object format only
   - Line 120: Updated `get_all_tasks()` to return IDs from both formats
   - Line 135: Updated `get_session_info()` to display both formats

## Backward Compatibility

These changes are **fully backward compatible**:
- ✅ Works with old string format: `["TASK-001", "TASK-002"]`
- ✅ Works with new object format: `[{"id": "TASK-001", ...}]`
- ✅ Works with mixed format: `["TASK-001", {"id": "TASK-002", ...}]`
- ✅ Works on Bash 3.2+ (macOS default) and Bash 4+

## Migration (Optional)

While the scripts now handle mixed formats, you can normalize your session files to the consistent object format using the migration script:

```bash
~/.claude/skills/scripts/taskflow-migrate-session.sh
```

This will convert all string-format tasks to object format with timestamps.

## Verified On

- ✅ macOS (Bash 3.2)
- ✅ Mixed format JSON (strings + objects)
- ✅ Session handoff operations
- ✅ Session info display

## Future Recommendations

1. Always use object format for new tasks (handled automatically by current scripts)
2. String format is legacy and supported for backward compatibility only
3. New task additions via `add_task()` will always use object format
