#!/bin/bash
# TaskFlow Status - One-line status summary with session name

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SESSION_FILE="$PROJECT_ROOT/.taskflow-session.json"

# Get session info
if [ -f "$SESSION_FILE" ] && command -v jq &> /dev/null; then
    SESSION_NAME=$(jq -r '.session_id // "no-session"' "$SESSION_FILE")
    CURRENT_TASK=$(jq -r '.current_task // empty' "$SESSION_FILE")
else
    SESSION_NAME="no-session"
    CURRENT_TASK=""
fi

# Count active tasks
ACTIVE_COUNT=$(grep -c "^### " ACTIVE.md 2>/dev/null || echo "0")

# Get git branch
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current)
    COMMIT=$(git rev-parse --short HEAD)
else
    BRANCH="unknown"
    COMMIT="unknown"
fi

# Check for uncommitted changes
if git diff-index --quiet HEAD -- 2>/dev/null; then
    GIT_STATUS="✅"
else
    GIT_STATUS="⚠️"
fi

# Token counts
ACTIVE_TOKENS=$(($(wc -c < ACTIVE.md) / 4))
BACKLOG_TOKENS=$(($(wc -c < BACKLOG.md) / 4))

# Display with session name prominently
echo "🔖 Session: $SESSION_NAME"
if [ -n "$CURRENT_TASK" ]; then
    echo "📍 Current: $CURRENT_TASK"
fi
echo "📊 ${ACTIVE_COUNT} active tasks | ${BRANCH}@${COMMIT} ${GIT_STATUS} | ACTIVE ${ACTIVE_TOKENS}tok | BACKLOG ${BACKLOG_TOKENS}tok"
