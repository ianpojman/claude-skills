#!/bin/bash
# Minimal status - no fancy formatting

# Use current directory or git root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 1

# Check for current task
if [ -f ".taskflow-current" ]; then
    CURRENT_TASK=$(cat .taskflow-current)
    TASK_FILE="docs/active/${CURRENT_TASK}.md"
    if [ -f "$TASK_FILE" ]; then
        TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${CURRENT_TASK}: //" || echo "Unknown")
        echo "📍 Current: $CURRENT_TASK - $TASK_TITLE"
    fi
fi

# Count tasks
total=$(grep -c "^###" ACTIVE.md 2>/dev/null || echo 0)
completed=$(grep -c "✅" ACTIVE.md 2>/dev/null || echo 0)
in_progress=$(grep -c "⏳ IN PROGRESS" ACTIVE.md 2>/dev/null || echo 0)

# Git info
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
commit=$(git rev-parse --short HEAD 2>/dev/null)

# Token counts
active_tokens=$(wc -c < ACTIVE.md | awk '{print int($1/4000)}')
backlog_tokens=$(wc -c < BACKLOG.md | awk '{print int($1/4000)}')

echo "📊 $total tasks | $in_progress active | $completed done"
echo "📁 $branch @ $commit"
echo "🔢 ACTIVE: ${active_tokens}K | BACKLOG: ${backlog_tokens}K"

# Occasionally show a tip (20% chance)
if [ $((RANDOM % 5)) -eq 0 ]; then
    echo ""
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/taskflow-tips.sh" 2>/dev/null || true
fi
