#!/bin/bash
# TaskFlow Merge - Merge another session into current

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 1

SESSION_NAME="$1"

if [ -z "$SESSION_NAME" ]; then
    echo "Usage: taskflow-merge.sh SESSION-NAME"
    echo ""
    echo "Available sessions:"
    ls -1 docs/handoff/ 2>/dev/null | grep -v ".sessions.json" | sed 's/\.md$//' | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

HANDOFF_FILE="docs/handoff/${SESSION_NAME}.md"

if [ ! -f "$HANDOFF_FILE" ]; then
    echo "❌ Session not found: $SESSION_NAME"
    echo ""
    echo "Available sessions:"
    ls -1 docs/handoff/ 2>/dev/null | grep -v ".sessions.json" | sed 's/\.md$//' | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

# Get current task (don't override it)
CURRENT_TASK=""
if [ -f ".taskflow-current" ]; then
    CURRENT_TASK=$(cat .taskflow-current)
fi

# Extract info from handoff
MERGE_TASK=$(grep "^\*\*Task ID\*\*:" "$HANDOFF_FILE" | sed 's/\*\*Task ID\*\*: //' || echo "")
MERGE_TITLE=$(grep "^\*\*Title\*\*:" "$HANDOFF_FILE" | sed 's/\*\*Title\*\*: //' || echo "")
MERGE_STATUS=$(grep "^\*\*Status\*\*:" "$HANDOFF_FILE" | sed 's/\*\*Status\*\*: //' || echo "")

echo "✓ Merging session: $SESSION_NAME"
echo ""
echo "Their Session:"
echo "  Task: ${MERGE_TASK:-N/A}"
echo "  Title: ${MERGE_TITLE:-N/A}"
echo "  Status: ${MERGE_STATUS:-N/A}"
echo ""

if [ -n "$CURRENT_TASK" ]; then
    echo "Your Session (unchanged):"
    echo "  Current task: $CURRENT_TASK"
    echo ""
fi

# Extract session notes and add to ACTIVE.md
SESSION_NOTES=$(sed -n '/## Recent Session Notes/,/##/p' "$HANDOFF_FILE" | grep -v "^##" || echo "")

if [ -n "$SESSION_NOTES" ] && [ -f "ACTIVE.md" ]; then
    MERGE_DATE=$(date +%Y-%m-%d)
    cat >> ACTIVE.md <<EOF

### 📅 Merged Session Notes - $MERGE_DATE (from $SESSION_NAME)

**Source**: $SESSION_NAME
**Task**: ${MERGE_TASK:-N/A} - ${MERGE_TITLE:-N/A}

$SESSION_NOTES

---
EOF
    echo "📝 Merged session notes added to ACTIVE.md"
else
    echo "ℹ️  No session notes to merge"
fi

echo ""
echo "📖 Full handoff: $HANDOFF_FILE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Your current task remains: ${CURRENT_TASK:-none}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
