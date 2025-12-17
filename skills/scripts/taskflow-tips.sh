#!/bin/bash
# TaskFlow Tips - Show helpful tips

TIPS=(
    "💡 Quick status: /tfs (only ~44 tokens!)"
    "💡 Start a task: /tfstart PARQ-003"
    "💡 Create handoff: /tfhandoff [optional-name]"
    "💡 List sessions: /tflist"
    "💡 Merge sessions: /tfmerge session-name (multi-agent sync!)"
    "💡 Show current task: /tfcurrent"
    "💡 Auto-naming: /tfhandoff without args uses task ID + timestamp"
    "💡 Session handoffs preserve running EMR clusters"
    "💡 Use /tfmerge to learn what another agent did"
    "💡 Clean slate: /tfstop clears current task"
    "💡 Resume sessions: /tfresume session-name"
    "💡 Named sessions: /tfhandoff my-custom-name"
    "💡 Multi-agent: Each agent gets its own session"
    "💡 Handoffs include git status and running processes"
    "💡 Compact ACTIVE.md: /tfc"
    "💡 Resume task details: /tfr BUG-017"
)

CATEGORY="$1"

if [ "$CATEGORY" == "all" ]; then
    echo "📚 All TaskFlow Tips:"
    echo ""
    for tip in "${TIPS[@]}"; do
        echo "  $tip"
    done
elif [ "$CATEGORY" == "session" ]; then
    echo "💡 Session Management Tips:"
    echo ""
    echo "  • Create: /tfhandoff [name]"
    echo "  • List: /tflist"
    echo "  • Resume: /tfresume session-name"
    echo "  • Merge: /tfmerge session-name"
elif [ "$CATEGORY" == "task" ]; then
    echo "💡 Task Management Tips:"
    echo ""
    echo "  • Start: /tfstart BUG-017 or /tfstart UI-003 \"Add dark mode\""
    echo "  • Current: /tfcurrent"
    echo "  • Stop: /tfstop"
    echo "  • Status: /tfs"
else
    # Random tip
    RANDOM_INDEX=$((RANDOM % ${#TIPS[@]}))
    echo "${TIPS[$RANDOM_INDEX]}"
fi
