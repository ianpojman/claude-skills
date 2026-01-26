#!/bin/bash
# TaskFlow List - Show all active tasks with status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                      TASKFLOW - ACTIVE TASKS                         ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$TASKFLOW_ROOT/ACTIVE.md" ]; then
    echo "❌ $TASKFLOW_ROOT/ACTIVE.md not found"
    exit 1
fi

# Extract all task headers (### lines with issue IDs)
echo "📋 Active Tasks:"
echo ""

grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -E '[A-Z]+-[0-9]+' | while IFS= read -r line; do
    # Extract issue ID
    issue_id=$(echo "$line" | grep -oE '[A-Z]+-[0-9]+' | head -1)

    # Extract status emoji
    status_emoji="  "  # Default: no status
    if echo "$line" | grep -q "🔴"; then
        status_emoji="🔴"
    elif echo "$line" | grep -q "⏳"; then
        status_emoji="⏳"
    elif echo "$line" | grep -q "✅"; then
        status_emoji="✅"
    elif echo "$line" | grep -q "🆕"; then
        status_emoji="🆕"
    fi

    # Extract description (remove ###, emojis, and issue ID)
    description=$(echo "$line" | sed 's/^###[[:space:]]*//' | sed "s/${issue_id}:[[:space:]]*//" | sed 's/🔴//' | sed 's/⏳//' | sed 's/✅//' | sed 's/🆕//' | sed 's/(IN PROGRESS)//' | sed 's/(COMPLETE)//' | xargs)

    # Display with better alignment
    # Format: emoji + space + ID (padded to 12 chars) + description
    printf "%s  %-12s  %s\n" "$status_emoji" "$issue_id" "$description"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count tasks by status
# Note: grep -c returns exit 1 when count is 0, so use || true to prevent set -e from exiting
total=$(grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -cE '[A-Z]+-[0-9]+' || true)
in_progress=$(grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -c "⏳" || true)
completed=$(grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -c "✅" || true)
new_tasks=$(grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -c "🆕" || true)
blocked=$(grep "^###" $TASKFLOW_ROOT/ACTIVE.md | grep -c "🔴" || true)

echo ""
echo "📊 Summary:"
echo "  • Total: $total tasks"
echo "  • In Progress: $in_progress ⏳"
echo "  • Completed: $completed ✅"
echo "  • New/Ready: $new_tasks 🆕"
echo "  • Blocked: $blocked 🔴"
echo ""

# Show git context
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current)
    commit=$(git rev-parse --short HEAD)
    echo "🔧 Git: $branch @ $commit"
    echo ""
fi

echo "💡 Use 'taskflow search <keyword>' to find specific issues"
