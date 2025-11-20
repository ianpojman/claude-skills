#!/bin/bash
# Token-efficient resume: Loads task index + specific task details

TASK_ID="$1"

if [ -z "$TASK_ID" ]; then
  echo "Usage: taskflow-resume.sh TASK-ID"
  echo ""
  echo "Available tasks:"
  grep "^###" ACTIVE.md | sed 's/^### /  /'
  exit 1
fi

# Show quick context
echo "📊 Active Tasks:"
grep -c "^###" ACTIVE.md | xargs echo "  Total:"
echo ""

# Load task details
TASK_FILE="docs/active/${TASK_ID}.md"

if [ -f "$TASK_FILE" ]; then
  echo "📋 Task Details (from $TASK_FILE):"
  echo ""
  cat "$TASK_FILE"
  echo ""
  echo "💡 Tip: Edit details in $TASK_FILE"
else
  echo "❌ Task file not found: $TASK_FILE"
  echo ""
  echo "Available tasks:"
  ls -1 docs/active/ | sed 's/\.md$//'
  exit 1
fi
