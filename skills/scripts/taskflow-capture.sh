#!/bin/bash
# TaskFlow Capture - Save current session state to $TASKFLOW_ROOT/ACTIVE.md (non-interactive)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

# Non-interactive mode: accept summary as argument
if [ -z "$1" ]; then
    echo "Usage: ./scripts/taskflow-capture.sh \"session summary\""
    echo ""
    echo "Example:"
    echo "  ./scripts/taskflow-capture.sh \"Fixed ETL-001. Next: test hour 23 validation\""
    exit 1
fi

SESSION_DATE=$(date +%Y-%m-%d)
SESSION_SUMMARY="$1"

# Get current task ID if available
CURRENT_TASK=""
if [ -f "$TASKFLOW_ROOT/.taskflow-current" ]; then
    CURRENT_TASK=$(cat $TASKFLOW_ROOT/.taskflow-current)
fi

# Build header with task ID if available
if [ -n "$CURRENT_TASK" ]; then
    HEADER="### 📅 [$CURRENT_TASK] Session Notes - ${SESSION_DATE}"
else
    HEADER="### 📅 Session Notes - ${SESSION_DATE}"
fi

# Append to $TASKFLOW_ROOT/ACTIVE.md
cat >> $TASKFLOW_ROOT/ACTIVE.md <<EOF

${HEADER}

${SESSION_SUMMARY}

---
EOF

echo "✅ Session summary added to $TASKFLOW_ROOT/ACTIVE.md"
echo ""
echo "Summary:"
echo "  ${SESSION_SUMMARY}"
