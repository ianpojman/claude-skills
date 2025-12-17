#!/bin/bash
# TaskFlow Resume Session - Load handoff and resume work with task selection

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 1

SESSION_ID="$1"
TASK_CHOICE="$2"

if [ -z "$SESSION_ID" ]; then
    echo "Usage: taskflow-resume-session.sh SESSION-ID [task-number]"
    echo ""
    echo "Available handoffs:"
    ls -1 docs/handoff/ 2>/dev/null | grep -v "^\\." | sed 's/\.md$//' | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

HANDOFF_FILE="docs/handoff/${SESSION_ID}.md"
METADATA_FILE="docs/handoff/.sessions.json"

if [ ! -f "$HANDOFF_FILE" ]; then
    echo "❌ Handoff file not found: $HANDOFF_FILE"
    echo ""
    echo "Available handoffs:"
    ls -1 docs/handoff/ 2>/dev/null | grep -v "^\\." | sed 's/\.md$//' | sed 's/^/  /' || echo "  (none)"
    exit 1
fi

# Display handoff summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Resuming session: $SESSION_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract tasks from handoff file
mapfile -t TASK_IDS < <(grep -E "^### [A-Z]+-[0-9]+:" "$HANDOFF_FILE" | grep -o '[A-Z]\+-[0-9]\+')
TASK_COUNT=${#TASK_IDS[@]}

if [ $TASK_COUNT -eq 0 ]; then
    echo "⚠️  No tasks found in this session"
    cat "$HANDOFF_FILE"
    exit 0
fi

# Show tasks
echo "Tasks in this session ($TASK_COUNT):"
echo ""
TASK_NUM=1
for TASK_ID in "${TASK_IDS[@]}"; do
    TASK_FILE="docs/active/${TASK_ID}.md"
    TASK_TITLE="Unknown"
    TASK_STATUS="Unknown"

    if [ -f "$TASK_FILE" ]; then
        TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${TASK_ID}: //" || echo "Unknown")
        TASK_STATUS=$(grep "^\*\*Status\*\*:" "$TASK_FILE" | head -1 | sed 's/\*\*Status\*\*: //' || echo "Unknown")
    fi

    echo "  $TASK_NUM) $TASK_ID - $TASK_TITLE"
    echo "     Status: $TASK_STATUS"
    TASK_NUM=$((TASK_NUM + 1))
done
echo ""

# Task selection
SELECTED_TASK=""

if [ -n "$TASK_CHOICE" ]; then
    # Task specified via command line
    if [[ "$TASK_CHOICE" =~ ^[0-9]+$ ]] && [ "$TASK_CHOICE" -ge 1 ] && [ "$TASK_CHOICE" -le $TASK_COUNT ]; then
        SELECTED_TASK="${TASK_IDS[$((TASK_CHOICE - 1))]}"
    else
        echo "❌ Invalid task number: $TASK_CHOICE (must be 1-$TASK_COUNT)"
        exit 1
    fi
elif [ $TASK_COUNT -eq 1 ]; then
    # Only one task, auto-select
    SELECTED_TASK="${TASK_IDS[0]}"
    echo "→ Auto-selected only task: $SELECTED_TASK"
else
    # Interactive selection
    echo "Which task do you want to resume?"
    read -p "Enter number (1-$TASK_COUNT) or 'all' to see full handoff: " choice
    echo ""

    if [ "$choice" = "all" ] || [ "$choice" = "a" ]; then
        cat "$HANDOFF_FILE"
        echo ""
        echo "Run '/tfstart TASK-ID' to start working on a specific task"
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $TASK_COUNT ]; then
        SELECTED_TASK="${TASK_IDS[$((choice - 1))]}"
    else
        echo "❌ Invalid selection"
        exit 1
    fi
fi

# Set selected task as current
if [ -n "$SELECTED_TASK" ]; then
    SESSION_SCRIPT="$HOME/.claude/skills/scripts/taskflow-session.sh"
    if [ -x "$SESSION_SCRIPT" ]; then
        "$SESSION_SCRIPT" add "$SELECTED_TASK" "in_progress"
        "$SESSION_SCRIPT" set-current "$SELECTED_TASK"
    else
        echo "$SELECTED_TASK" > .taskflow-current
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✓ Now working on: $SELECTED_TASK"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show task details
    TASK_FILE="docs/active/${SELECTED_TASK}.md"
    if [ -f "$TASK_FILE" ]; then
        cat "$TASK_FILE"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Quick commands:"
    echo "  /tfs          - Check status"
    echo "  /tfcurrent    - Show current task"
    echo "  /tfstart TASK - Switch to different task"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
