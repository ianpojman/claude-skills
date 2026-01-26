#!/bin/bash
# Ultra-light ACTIVE.md compactor - Archive old session notes and completed tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")
ACTIVE_FILE="$TASKFLOW_ROOT/ACTIVE.md"
NOTES_DIR="$TASKFLOW_ROOT/docs/session-notes"
COMPLETED_DIR="$TASKFLOW_ROOT/docs/completed"
ACTIVE_TASKS_DIR="$TASKFLOW_ROOT/docs/active"
TODAY=$(date +%Y-%m-%d)
KEEP_DAYS=3  # Keep last 3 days of notes in ACTIVE.md

# Ensure notes directory exists
mkdir -p "$NOTES_DIR"

# Phase 1: Remove session notes (format: ### 2025-11-26: ...)
echo "🔍 Checking for session notes in ACTIVE.md..."

if grep -q "^### 202[0-9]-" "$ACTIVE_FILE"; then
  # Use Python to remove all session notes
  python3 <<PYTHON
import re

with open("$ACTIVE_FILE", 'r') as f:
    lines = f.readlines()

# Find session note lines (### 2025-)
session_note_lines = [i for i, line in enumerate(lines) if re.match(r'^### 202\d-', line)]

if session_note_lines:
    start_removal = session_note_lines[0]

    # Find "## Summary" section
    summary_idx = next((i for i in range(start_removal, len(lines)) if lines[i].startswith('## Summary')), None)

    if summary_idx:
        new_lines = lines[:start_removal] + lines[summary_idx:]
    else:
        new_lines = lines[:start_removal]

    with open("$ACTIVE_FILE", 'w') as f:
        f.writelines(new_lines)

    print(f"✅ Removed {len(lines) - len(new_lines)} lines of session notes from ACTIVE.md")
PYTHON

else
  echo "✅ No session notes to compact"
fi

# Phase 1.5: Slim task descriptions (keep only header + details link)
echo "🔍 Slimming task descriptions..."

if false; then  # Disabled for now - only run manually
# Original session notes logic for 📅 format (keep for backward compatibility)
SESSION_START=$(grep -n "^### 📅 Session Notes" "$ACTIVE_FILE" | head -1 | cut -d: -f1)

if [ ! -z "$SESSION_START" ]; then

# Split ACTIVE.md into header and session notes
head -n $((SESSION_START - 1)) "$ACTIVE_FILE" > /tmp/active_header.md
tail -n +$SESSION_START "$ACTIVE_FILE" > /tmp/active_notes.md

# Parse session notes and separate old vs recent
CUTOFF_DATE=$(date -v-${KEEP_DAYS}d +%Y-%m-%d 2>/dev/null || date -d "${KEEP_DAYS} days ago" +%Y-%m-%d)

awk -v cutoff="$CUTOFF_DATE" -v notes_dir="$NOTES_DIR" '
BEGIN { current_date = ""; note_buffer = ""; recent_notes = ""; old_count = 0 }

/^### 📅 Session Notes - / {
  # Save previous note if exists
  if (current_date != "" && note_buffer != "") {
    if (current_date >= cutoff) {
      recent_notes = recent_notes note_buffer
    } else {
      # Archive old note
      file = notes_dir "/" current_date ".md"
      print note_buffer >> file
      old_count++
    }
  }

  # Extract date from header
  match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)
  if (RSTART > 0) {
    current_date = substr($0, RSTART, RLENGTH)
  } else {
    current_date = "unknown"
  }

  note_buffer = $0 "\n"
  next
}

/^---$/ {
  note_buffer = note_buffer $0 "\n"
  next
}

{
  note_buffer = note_buffer $0 "\n"
}

END {
  # Save last note
  if (current_date != "" && note_buffer != "") {
    if (current_date >= cutoff) {
      recent_notes = recent_notes note_buffer
    } else {
      file = notes_dir "/" current_date ".md"
      print note_buffer >> file
      old_count++
    }
  }

  print recent_notes
  print "ARCHIVED_COUNT=" old_count > "/tmp/compact_stats"
}
' /tmp/active_notes.md > /tmp/active_recent_notes.md

# Combine header + recent notes
cat /tmp/active_header.md /tmp/active_recent_notes.md > "$ACTIVE_FILE"

# Cleanup
rm -f /tmp/active_header.md /tmp/active_notes.md /tmp/active_recent_notes.md

# Show stats
ARCHIVED=$(grep ARCHIVED_COUNT /tmp/compact_stats | cut -d= -f2)
rm -f /tmp/compact_stats

  if [ "$ARCHIVED" -gt 0 ]; then
    echo "✅ Compacted ACTIVE.md: archived $ARCHIVED old session note(s) to $NOTES_DIR/"
    echo "📊 Keeping last $KEEP_DAYS days of notes in ACTIVE.md"
  else
    echo "✅ ACTIVE.md already compact (all notes within last $KEEP_DAYS days)"
  fi
fi
fi  # End of "if false" disabled block

# Phase 2: Check for completed tasks in docs/active/ and move to docs/completed/
echo ""
echo "🔍 Scanning docs/active/ for completed tasks..."

if [ ! -d "$ACTIVE_TASKS_DIR" ]; then
  echo "⚠️  No docs/active/ directory found"
  exit 0
fi

COMPLETED_TASKS=()
for task_file in "$ACTIVE_TASKS_DIR"/*.md; do
  [ -f "$task_file" ] || continue

  # Check first 10 lines for completion status
  if head -n 10 "$task_file" | grep -qE "Status.*:.*✅.*(COMPLETE|VALIDATED|FIXED|DONE)"; then
    task_name=$(basename "$task_file")
    COMPLETED_TASKS+=("$task_name")
  fi
done

if [ ${#COMPLETED_TASKS[@]} -eq 0 ]; then
  echo "✅ No completed tasks found in docs/active/"
  exit 0
fi

# Create today's completed directory
mkdir -p "$COMPLETED_DIR/$TODAY"

# Move completed tasks
echo "📦 Found ${#COMPLETED_TASKS[@]} completed task(s):"
for task_name in "${COMPLETED_TASKS[@]}"; do
  echo "   - $task_name"
  mv "$ACTIVE_TASKS_DIR/$task_name" "$COMPLETED_DIR/$TODAY/"
done

echo ""
echo "✅ Archived ${#COMPLETED_TASKS[@]} completed task(s) to $COMPLETED_DIR/$TODAY/"
echo "⚠️  MANUAL STEP REQUIRED: Update ACTIVE.md to:"
echo "   1. Remove archived tasks from Active Tasks section"
echo "   2. Add them to 'Recently Completed' section"
echo "   3. Update task counts in Summary section"
echo ""
echo "Completed tasks: ${COMPLETED_TASKS[@]}"
