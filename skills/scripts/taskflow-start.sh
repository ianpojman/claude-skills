#!/bin/bash
# TaskFlow Start - Set current task for this session

set -e

if [ -z "$1" ]; then
    echo "Usage: taskflow-start.sh ISSUE-ID|\"task description\""
    echo ""
    echo "Examples:"
    echo "  taskflow-start.sh PARQ-003              # Start existing task"
    echo "  taskflow-start.sh BUG-017 \"Fix login bug\"  # Create with ID"
    echo "  taskflow-start.sh \"Fix login bug\"       # Prompts for ID"
    echo ""
    echo "Use meaningful prefixes like Jira: BUG-001, UI-017, PERF-042"
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CURRENT_FILE="$PROJECT_ROOT/.taskflow-current"
ACTIVE_MD="$PROJECT_ROOT/ACTIVE.md"

# Check if input is an existing task ID or a new task description
if [[ "$1" =~ ^[A-Z]+-[0-9]+$ ]]; then
    TASK_ID="$1"
    TASK_FILE="$PROJECT_ROOT/docs/active/${TASK_ID}.md"

    # Check if task exists OR if description provided (create new)
    if [ ! -f "$TASK_FILE" ]; then
        if [ -n "$2" ]; then
            # ID + description provided = create new task with that ID
            TASK_DESC="$2"
            mkdir -p "$(dirname "$TASK_FILE")"

            # Create task file
            cat > "$TASK_FILE" <<EOF
# ${TASK_ID}: ${TASK_DESC}

**Status**: in_progress
**Created**: $(date +"%Y-%m-%d %H:%M")

## Description

${TASK_DESC}

## Tasks

- [ ] TODO

## Notes

(Session notes will be added here)
EOF

            # Add to ACTIVE.md
            sed -i.bak "/^## 🚀 Active Tasks/a\\
\\
### ${TASK_ID}: ${TASK_DESC}\\
[Details →](docs/active/${TASK_ID}.md)
" "$ACTIVE_MD"

            echo "✅ Created new task: $TASK_ID"
            echo ""
        else
            echo "❌ Task file not found: $TASK_FILE"
            echo ""
            echo "Available tasks:"
            ls -1 "$PROJECT_ROOT/docs/active/" 2>/dev/null | sed 's/\.md$//' || echo "  (none)"
            echo ""
            echo "Create with: /tfstart $TASK_ID \"description here\""
            exit 1
        fi
    fi
else
    # New task - search for matching issue first
    TASK_DESC="$1"

    # Search for matching task in ACTIVE.md
    MATCHING_TASK=$(grep -i "### [A-Z]*-[0-9]*:.*${TASK_DESC}" "$ACTIVE_MD" 2>/dev/null | head -1 || echo "")

    if [ -n "$MATCHING_TASK" ]; then
        # Found matching task
        TASK_ID=$(echo "$MATCHING_TASK" | grep -o '[A-Z]*-[0-9]*' | head -1)
        echo "📌 Found matching task: $TASK_ID"
        echo "   $MATCHING_TASK"
        echo ""
        read -p "Use this task? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            TASK_FILE="$PROJECT_ROOT/docs/active/${TASK_ID}.md"
        else
            echo "Creating new task..."
            TASK_ID=""
        fi
    fi

    # Create new task if no match or user declined
    if [ -z "$TASK_ID" ]; then
        # Prompt for custom ID prefix (Jira-style)
        echo "📝 Creating new task: \"$TASK_DESC\""
        echo ""
        echo "Enter issue ID (e.g., BUG-001, UI-017, PERF-042):"
        read -p "> " CUSTOM_ID

        # Validate the ID format
        if [[ ! "$CUSTOM_ID" =~ ^[A-Z]+-[0-9]+$ ]]; then
            echo ""
            echo "❌ Invalid format. Use: PREFIX-NUMBER"
            echo "   Examples: BUG-001, UI-017, PERF-042, FIX-003"
            exit 1
        fi

        TASK_ID="$CUSTOM_ID"

        TASK_FILE="$PROJECT_ROOT/docs/active/${TASK_ID}.md"
        mkdir -p "$(dirname "$TASK_FILE")"

        # Create task file
        cat > "$TASK_FILE" <<EOF
# ${TASK_ID}: ${TASK_DESC}

**Status**: in_progress
**Created**: $(date +"%Y-%m-%d %H:%M")

## Description

${TASK_DESC}

## Tasks

- [ ] TODO

## Notes

(Session notes will be added here)
EOF

        # Add to ACTIVE.md
        sed -i.bak "/^## 🚀 Active Tasks/a\\
\\
### ${TASK_ID}: ${TASK_DESC}\\
[Details →](docs/active/${TASK_ID}.md)
" "$ACTIVE_MD"

        echo "✅ Created new task: $TASK_ID"
        echo ""
    fi
fi

# Extract task title from file
TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${TASK_ID}: //" || echo "Unknown Task")

# Update session tracking
SESSION_SCRIPT="$HOME/.claude/skills/scripts/taskflow-session.sh"
if [ -x "$SESSION_SCRIPT" ]; then
    "$SESSION_SCRIPT" add "$TASK_ID" "in_progress"
    "$SESSION_SCRIPT" set-current "$TASK_ID"
else
    # Fallback to legacy single-task tracking
    echo "$TASK_ID" > "$CURRENT_FILE"
fi

echo "📍 Now working on: $TASK_ID - $TASK_TITLE"
echo ""

# Check if session is auto-named and show reminder
SESSION_FILE="$PROJECT_ROOT/.taskflow-session.json"
if [ -f "$SESSION_FILE" ] && command -v jq &> /dev/null; then
    AUTO_NAMED=$(jq -r '.auto_named // false' "$SESSION_FILE")
    SESSION_NAME=$(jq -r '.session_id // "unknown"' "$SESSION_FILE")

    if [ "$AUTO_NAMED" = "true" ]; then
        echo "💡 Session auto-named: $SESSION_NAME"
        echo "   Rename for crash recovery: /name custom-name"
        echo ""
    fi
fi

echo "Quick commands:"
echo "  /name custom-name  - Rename session (for crash recovery!)"
echo "  /save              - Save session state"
echo "  /tfs               - Show status"
