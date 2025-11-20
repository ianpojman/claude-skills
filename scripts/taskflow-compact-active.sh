#!/bin/bash
# Ultra-light ACTIVE.md compactor - Archive old session notes on the fly

set -e

PROJECT_ROOT="${1:-.}"
ACTIVE_FILE="$PROJECT_ROOT/ACTIVE.md"
NOTES_DIR="$PROJECT_ROOT/docs/session-notes"
TODAY=$(date +%Y-%m-%d)
KEEP_DAYS=3  # Keep last 3 days of notes in ACTIVE.md

# Ensure notes directory exists
mkdir -p "$NOTES_DIR"

# Extract session notes section
SESSION_START=$(grep -n "^### 📅 Session Notes" "$ACTIVE_FILE" | head -1 | cut -d: -f1)

if [ -z "$SESSION_START" ]; then
  echo "✅ No session notes to compact"
  exit 0
fi

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
