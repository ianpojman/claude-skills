#!/bin/bash
# Token-efficient resume: Loads task index + specific task details

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

TASK_ID="$1"

if [ -z "$TASK_ID" ]; then
  echo "Usage: taskflow-resume.sh TASK-ID"
  echo ""
  echo "Available tasks:"
  grep "^###" $TASKFLOW_ROOT/ACTIVE.md | sed 's/^### /  /'
  exit 1
fi

# Show quick context
echo "📊 Active Tasks:"
grep -c "^###" $TASKFLOW_ROOT/ACTIVE.md | xargs echo "  Total:"
echo ""

# Load task details
TASK_FILE="$TASKFLOW_ROOT/docs/active/${TASK_ID}.md"

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
  ls -1 $TASKFLOW_ROOT/docs/active/ | sed 's/\.md$//'
  exit 1
fi
