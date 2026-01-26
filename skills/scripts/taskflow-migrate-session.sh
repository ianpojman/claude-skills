#!/bin/bash
# TaskFlow Session Migration - Normalize task format to objects
# Converts string-format tasks to object format for consistency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")
SESSION_FILE="$TASKFLOW_ROOT/.taskflow-session.json"

if [ ! -f "$SESSION_FILE" ]; then
    echo "No session file found at: $SESSION_FILE"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for migration"
    echo "Install with: brew install jq"
    exit 1
fi

# Check if migration is needed
STRING_COUNT=$(jq '[.tasks[] | select(type == "string")] | length' "$SESSION_FILE")

if [ "$STRING_COUNT" -eq 0 ]; then
    echo "✓ Session file already normalized (all tasks are objects)"
    exit 0
fi

echo "Found $STRING_COUNT string-format task(s) to migrate"
echo ""

# Create backup
BACKUP_FILE="${SESSION_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SESSION_FILE" "$BACKUP_FILE"
echo "📦 Backup created: $BACKUP_FILE"
echo ""

# Migrate string tasks to object format
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

TMP=$(mktemp)
jq --arg now "$NOW" '
  .tasks |= map(
    if type == "string" then
      {
        "id": .,
        "started": $now,
        "last_updated": $now,
        "status": "in_progress",
        "migrated": true
      }
    else
      .
    end
  )
' "$SESSION_FILE" > "$TMP"

# Validate the migrated JSON
if jq empty "$TMP" 2>/dev/null; then
    mv "$TMP" "$SESSION_FILE"
    echo "✅ Migration complete!"
    echo ""
    echo "Summary:"
    echo "  - Migrated: $STRING_COUNT task(s)"
    echo "  - Format: All tasks now use object format"
    echo "  - Backup: $BACKUP_FILE"
    echo ""
    echo "Migrated tasks (marked with 'migrated: true'):"
    jq -r '.tasks[] | select(.migrated == true) | "  - \(.id)"' "$SESSION_FILE"
else
    echo "❌ Migration failed - JSON validation error"
    echo "   Original file preserved"
    rm -f "$TMP"
    exit 1
fi
