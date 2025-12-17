#!/bin/bash
# TaskFlow Session Management - Track multiple tasks per session

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SESSION_FILE="$PROJECT_ROOT/.taskflow-session.json"

# Initialize session file if it doesn't exist
init_session() {
    local SESSION_NAME="${1:-}"
    local AUTO_NAMED=false

    if [ ! -f "$SESSION_FILE" ]; then
        # Use provided name or auto-generate from task context
        if [ -n "$SESSION_NAME" ]; then
            SESSION_ID=$(echo "$SESSION_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        else
            # Smart auto-naming: use current task or date
            if [ -f "$PROJECT_ROOT/.taskflow-current" ]; then
                CURRENT_TASK=$(cat "$PROJECT_ROOT/.taskflow-current" 2>/dev/null || echo "")
                if [ -n "$CURRENT_TASK" ]; then
                    # Use task ID as session name (e.g., "perf-009-work")
                    SESSION_ID=$(echo "$CURRENT_TASK" | tr '[:upper:]' '[:lower:]')-work
                    AUTO_NAMED=true
                else
                    SESSION_ID=$(date +%Y-%m-%d-%H%M)
                fi
            else
                SESSION_ID=$(date +%Y-%m-%d-%H%M)
            fi
        fi

        cat > "$SESSION_FILE" <<EOF
{
  "session_id": "$SESSION_ID",
  "started": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tasks": [],
  "current_task": null,
  "auto_named": $AUTO_NAMED
}
EOF
        if [ "$AUTO_NAMED" = true ]; then
            echo "✓ Session auto-named: $SESSION_ID (rename: /name custom-name)" >&2
        else
            echo "✓ Session started: $SESSION_ID" >&2
        fi
    fi
}

# Set session name (rename existing session)
set_session_name() {
    local NEW_NAME="$1"

    if [ -z "$NEW_NAME" ]; then
        echo "Error: Session name required"
        exit 1
    fi

    init_session

    SESSION_ID=$(echo "$NEW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    if command -v jq &> /dev/null; then
        TMP=$(mktemp)
        jq ".session_id = \"$SESSION_ID\"" "$SESSION_FILE" > "$TMP"
        mv "$TMP" "$SESSION_FILE"
        echo "✓ Session renamed: $SESSION_ID"
    else
        echo "Error: jq not installed"
        exit 1
    fi
}

# Add or update a task in the session
add_task() {
    local TASK_ID="$1"
    local STATUS="${2:-in_progress}"

    init_session

    local NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if command -v jq &> /dev/null; then
        # Check if task already exists (handle both string and object formats)
        TASK_EXISTS=$(jq -r ".tasks[] | if type == \"string\" then . else .id end | select(. == \"$TASK_ID\")" "$SESSION_FILE" 2>/dev/null || echo "")

        if [ -n "$TASK_EXISTS" ]; then
            # Update existing task (only works for object format)
            TMP=$(mktemp)
            jq "(.tasks[] | select(type == \"object\" and .id == \"$TASK_ID\") | .last_updated) = \"$NOW\" |
                (.tasks[] | select(type == \"object\" and .id == \"$TASK_ID\") | .status) = \"$STATUS\"" "$SESSION_FILE" > "$TMP"
            mv "$TMP" "$SESSION_FILE"
        else
            # Add new task
            TMP=$(mktemp)
            jq ".tasks += [{\"id\": \"$TASK_ID\", \"started\": \"$NOW\", \"last_updated\": \"$NOW\", \"status\": \"$STATUS\"}]" "$SESSION_FILE" > "$TMP"
            mv "$TMP" "$SESSION_FILE"
        fi
    else
        echo "Warning: jq not installed, session tracking limited"
    fi
}

# Set current task
set_current() {
    local TASK_ID="$1"

    init_session

    if command -v jq &> /dev/null; then
        TMP=$(mktemp)
        jq ".current_task = \"$TASK_ID\"" "$SESSION_FILE" > "$TMP"
        mv "$TMP" "$SESSION_FILE"
    fi

    # Also update legacy file for compatibility
    echo "$TASK_ID" > "$PROJECT_ROOT/.taskflow-current"
}

# Get current task
get_current() {
    init_session

    if command -v jq &> /dev/null; then
        jq -r '.current_task // empty' "$SESSION_FILE"
    else
        cat "$PROJECT_ROOT/.taskflow-current" 2>/dev/null || echo ""
    fi
}

# Get all tasks in session
get_all_tasks() {
    init_session

    if command -v jq &> /dev/null; then
        # Handle both string and object formats for backward compatibility
        jq -r '.tasks[] | if type == "string" then . else .id end' "$SESSION_FILE"
    else
        echo ""
    fi
}

# Get session info
get_session_info() {
    init_session

    if command -v jq &> /dev/null; then
        echo "Session ID: $(jq -r '.session_id' "$SESSION_FILE")"
        echo "Started: $(jq -r '.started' "$SESSION_FILE")"
        echo "Tasks worked on:"
        # Handle both string and object formats
        jq -r '.tasks[] | if type == "string" then "  - \(.)" else "  - \(.id) (\(.status)) - last updated: \(.last_updated)" end' "$SESSION_FILE"
        echo ""
        echo "Current task: $(jq -r '.current_task // "none"' "$SESSION_FILE")"
    else
        echo "jq not installed - install for full session tracking"
    fi
}

# Clear session (start fresh)
clear_session() {
    rm -f "$SESSION_FILE"
    rm -f "$PROJECT_ROOT/.taskflow-current"
    echo "✓ Session cleared"
}

# Main command dispatcher
case "${1:-}" in
    init)
        init_session "$2"
        if [ -z "$2" ]; then
            echo "✓ Session initialized (auto-named)"
        fi
        ;;
    set-name)
        set_session_name "$2"
        ;;
    add)
        add_task "$2" "${3:-in_progress}"
        echo "✓ Added/updated task: $2"
        ;;
    set-current)
        set_current "$2"
        echo "✓ Current task: $2"
        ;;
    get-current)
        get_current
        ;;
    get-all)
        get_all_tasks
        ;;
    info)
        get_session_info
        ;;
    clear)
        clear_session
        ;;
    *)
        echo "TaskFlow Session Management"
        echo ""
        echo "Usage: taskflow-session.sh [command]"
        echo ""
        echo "Commands:"
        echo "  init [name]       - Initialize new session (optional name)"
        echo "  set-name NAME     - Rename current session"
        echo "  add TASK-ID       - Add task to session"
        echo "  set-current ID    - Set current task"
        echo "  get-current       - Get current task ID"
        echo "  get-all           - Get all task IDs in session"
        echo "  info              - Show session info"
        echo "  clear             - Clear session (start fresh)"
        ;;
esac
