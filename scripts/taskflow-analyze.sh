#!/bin/bash
# TaskFlow Analyze - Token usage analysis

set -e


echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    TASKFLOW TOKEN ANALYSIS                           ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo

echo "TOKEN USAGE:"
ACTIVE_BYTES=$(wc -c < ACTIVE.md)
BACKLOG_BYTES=$(wc -c < BACKLOG.md)
ACTIVE_TOKENS=$((ACTIVE_BYTES / 4))
BACKLOG_TOKENS=$((BACKLOG_BYTES / 4))

echo "  ACTIVE.md:   ${ACTIVE_TOKENS} tokens $([ $ACTIVE_TOKENS -lt 2000 ] && echo '✅' || echo '❌') (budget: 2K)"
echo "  BACKLOG.md:  ${BACKLOG_TOKENS} tokens $([ $BACKLOG_TOKENS -lt 10000 ] && echo '✅' || echo '❌') (budget: 10K)"
echo

if [ $BACKLOG_TOKENS -gt 10000 ]; then
    OVER=$((BACKLOG_TOKENS - 10000))
    echo "⚠️  BACKLOG.md is ${OVER} tokens over budget!"
    echo
fi

echo "ARCHIVAL CANDIDATES (✅ Complete):"
grep -B2 "^### Status:.*✅\|^### Status:.*Complete" BACKLOG.md 2>/dev/null | grep "^## " | sed 's/^## /  • /' || echo "  None found"
echo

if [ $BACKLOG_TOKENS -gt 10000 ]; then
    echo "💡 RECOMMENDATION: Run ./scripts/taskflow-compact.sh"
fi
