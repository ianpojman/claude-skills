#!/bin/bash
# TaskFlow Current - Show current task

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")
CURRENT_FILE="$TASKFLOW_ROOT/.taskflow-current"

if [ ! -f "$CURRENT_FILE" ]; then
    echo "❌ No current task set"
    echo ""
    echo "Start a task with: /tfstart TASK-ID"
    exit 0
fi

TASK_ID=$(cat "$CURRENT_FILE")
TASK_FILE="$TASKFLOW_ROOT/docs/active/${TASK_ID}.md"

if [ ! -f "$TASK_FILE" ]; then
    echo "⚠️  Current task file not found: $TASK_ID"
    echo "   (task may have been moved or completed)"
    exit 1
fi

# Extract key info from task file
TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${TASK_ID}: //" || echo "Unknown")
TASK_STATUS=$(grep "^\*\*Status\*\*:" "$TASK_FILE" | head -1 | sed 's/\*\*Status\*\*: //' || echo "Unknown")

echo "📍 Current Task: $TASK_ID - $TASK_TITLE"
echo "📊 Status: $TASK_STATUS"
echo ""
echo "Full details: docs/active/${TASK_ID}.md"
