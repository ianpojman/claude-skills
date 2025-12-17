#!/bin/bash
# TaskFlow Stop - Clear current task

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CURRENT_FILE="$PROJECT_ROOT/.taskflow-current"

if [ ! -f "$CURRENT_FILE" ]; then
    echo "✓ No current task was set"
    exit 0
fi

TASK_ID=$(cat "$CURRENT_FILE")
rm "$CURRENT_FILE"

echo "✓ Cleared current task: $TASK_ID"
