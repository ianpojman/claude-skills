#!/bin/bash
# TaskFlow - Main entry point

set -e

# Store script directory for calling other scripts
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse command
CMD="${1:-status}"

case "$CMD" in
    status|"")
        # Compact default view: tasks + quick stats
        if [ ! -f "ACTIVE.md" ]; then
            echo "❌ ACTIVE.md not found - TaskFlow not initialized"
            exit 1
        fi

        # Quick task list (first 5 tasks)
        echo "📋 Active Tasks:"
        grep "^###" ACTIVE.md | grep -E '[A-Z]+-[0-9]+' | head -5 | while IFS= read -r line; do
            issue_id=$(echo "$line" | grep -oE '[A-Z]+-[0-9]+' | head -1)
            status_emoji=$(echo "$line" | grep -oE '(🔴|⏳|✅|🆕)' | head -1)
            description=$(echo "$line" | sed 's/^###[[:space:]]*//' | sed "s/${issue_id}:[[:space:]]*//" | sed 's/🔴//' | sed 's/⏳//' | sed 's/✅//' | sed 's/🆕//' | sed 's/(IN PROGRESS)//' | sed 's/(COMPLETE)//' | xargs | cut -c1-60)
            printf "  %s %-15s %s\n" "$status_emoji" "$issue_id" "$description"
        done

        # Task count
        total=$(grep "^###" ACTIVE.md | grep -cE '[A-Z]+-[0-9]+' || echo "0")
        if [ "$total" -gt 5 ]; then
            echo "  ... and $((total - 5)) more"
        fi
        echo ""

        # Token status
        ACTIVE_TOKENS=$(($(wc -c < ACTIVE.md) / 4))
        BACKLOG_TOKENS=$(($(wc -c < BACKLOG.md 2>/dev/null || echo "0") / 4))
        ACTIVE_STATUS=$([ $ACTIVE_TOKENS -lt 2000 ] && echo '✅' || echo '⚠️')
        BACKLOG_STATUS=$([ $BACKLOG_TOKENS -lt 10000 ] && echo '✅' || echo '⚠️')

        echo "📊 Status: ${total} tasks | ACTIVE ${ACTIVE_TOKENS}tok ${ACTIVE_STATUS} | BACKLOG ${BACKLOG_TOKENS}tok ${BACKLOG_STATUS}"

        # Git context
        if git rev-parse --git-dir > /dev/null 2>&1; then
            branch=$(git branch --show-current)
            commit=$(git rev-parse --short HEAD)
            echo "🔧 Git: $branch @ $commit"
        fi

        echo ""
        echo "💡 Run 'taskflow help' for more commands"
        ;;

    help|--help|-h)
        cat <<EOF
TaskFlow - Token-Efficient Task Management

USAGE:
  taskflow [command]

COMMANDS:
  (no command)    Show active tasks and status (default)
  list            List all active tasks with full details
  search <query>  Search issues by keyword
  status          Quick one-line status
  init            Generate session resumption prompt
  capture "msg"   Capture session notes
  handoff ["msg"] Generate end-of-session handoff
  analyze         Token usage analysis
  validate        Check link integrity
  help            Show this message

EXAMPLES:
  taskflow                          # Show active tasks
  taskflow list                     # Full task list
  taskflow search EMR               # Find EMR-related issues
  taskflow capture "Fixed ETL-001"  # Save session note
  taskflow handoff                  # Generate handoff

SCRIPTS:
  All commands map to ./scripts/taskflow-<command>.sh

DOCUMENTATION:
  See ~/.claude/skills/taskflow/skill.md for full details
EOF
        ;;

    list)
        "${SCRIPT_DIR}/taskflow-list.sh"
        ;;

    search)
        if [ -z "$2" ]; then
            echo "Usage: taskflow search <query>"
            exit 1
        fi
        "${SCRIPT_DIR}/taskflow-search.sh" "$2"
        ;;

    init|capture|handoff|analyze|validate)
        if [ -f "${SCRIPT_DIR}/taskflow-${CMD}.sh" ]; then
            shift
            "${SCRIPT_DIR}/taskflow-${CMD}.sh" "$@"
        else
            echo "❌ Command '$CMD' not implemented"
            exit 1
        fi
        ;;

    *)
        echo "❌ Unknown command: $CMD"
        echo "Run 'taskflow help' for usage"
        exit 1
        ;;
esac
