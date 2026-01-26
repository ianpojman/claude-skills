#!/bin/bash
# TaskFlow Analyze - Token usage analysis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    TASKFLOW TOKEN ANALYSIS                           ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo

echo "TOKEN USAGE:"
ACTIVE_BYTES=$(wc -c < $TASKFLOW_ROOT/ACTIVE.md)
BACKLOG_BYTES=$(wc -c < $TASKFLOW_ROOT/BACKLOG.md)
ACTIVE_TOKENS=$((ACTIVE_BYTES / 4))
BACKLOG_TOKENS=$((BACKLOG_BYTES / 4))

echo "  $TASKFLOW_ROOT/ACTIVE.md:   ${ACTIVE_TOKENS} tokens $([ $ACTIVE_TOKENS -lt 2000 ] && echo '✅' || echo '❌') (budget: 2K)"
echo "  $TASKFLOW_ROOT/BACKLOG.md:  ${BACKLOG_TOKENS} tokens $([ $BACKLOG_TOKENS -lt 10000 ] && echo '✅' || echo '❌') (budget: 10K)"
echo

if [ $BACKLOG_TOKENS -gt 10000 ]; then
    OVER=$((BACKLOG_TOKENS - 10000))
    echo "⚠️  $TASKFLOW_ROOT/BACKLOG.md is ${OVER} tokens over budget!"
    echo
fi

echo "ARCHIVAL CANDIDATES (✅ Complete):"
grep -B2 "^### Status:.*✅\|^### Status:.*Complete" $TASKFLOW_ROOT/BACKLOG.md 2>/dev/null | grep "^## " | sed 's/^## /  • /' || echo "  None found"
echo

if [ $BACKLOG_TOKENS -gt 10000 ]; then
    echo "💡 RECOMMENDATION: Run ./scripts/taskflow-compact.sh"
fi
