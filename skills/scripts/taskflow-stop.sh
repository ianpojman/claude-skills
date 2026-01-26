#!/bin/bash
# TaskFlow Stop - Clear current task

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")
CURRENT_FILE="$TASKFLOW_ROOT/.taskflow-current"

if [ ! -f "$CURRENT_FILE" ]; then
    echo "✓ No current task was set"
    exit 0
fi

TASK_ID=$(cat "$CURRENT_FILE")
rm "$CURRENT_FILE"

echo "✓ Cleared current task: $TASK_ID"
