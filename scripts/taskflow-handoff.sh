#!/bin/bash
# TaskFlow Handoff - Generate full context prompt for new sessions

set -e


echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                      TASKFLOW HANDOFF                                ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if --no-capture flag is passed
SKIP_CAPTURE=false
if [[ "$1" == "--no-capture" ]]; then
    SKIP_CAPTURE=true
    shift
fi

# Check if session summary is provided as argument
if [ -n "$1" ] && [ "$SKIP_CAPTURE" = false ]; then
    echo "📝 Capturing session summary..."
    SESSION_DATE=$(date +%Y-%m-%d)
    SESSION_ENTRY="
### 📅 Session Notes - ${SESSION_DATE}

$1

---
"
    echo "$SESSION_ENTRY" >> ACTIVE.md
    echo "✅ Session summary added to ACTIVE.md"
    echo ""
elif [ "$SKIP_CAPTURE" = false ]; then
    echo "💡 Tip: Pass session summary as argument to skip prompts"
    echo "   Example: ./scripts/taskflow-handoff.sh \"Fixed ETL-001, started CAT-004\""
    echo ""
fi

# Extract active issue IDs from ACTIVE.md
if [ -f "ACTIVE.md" ]; then
    echo "📋 Active Issues:"
    echo ""

    # Find issue IDs in headers (CAT-003, SPARSE-001, etc.)
    grep -oE '[A-Z]+-[0-9]+' ACTIVE.md | sort -u | while read issue_id; do
        # Get the first line of context for this issue
        context=$(grep -A 1 "$issue_id" ACTIVE.md | head -2 | tail -1 | sed 's/^[*# ]*//' | cut -c1-70)
        echo "  • $issue_id: $context"
    done

    echo ""
fi

# Show current git branch and status
echo "🔧 Git Context:"
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current)
    commit=$(git rev-parse --short HEAD)
    echo "  Branch: $branch"
    echo "  Commit: $commit"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "  Status: ⚠️ Uncommitted changes"
    else
        echo "  Status: ✅ Clean"
    fi
fi
echo ""

# Show running background processes (EMR clusters, etc.)
echo "🚀 Active Processes:"

# Check for EMR clusters
if command -v aws &> /dev/null; then
    clusters=$(aws emr list-clusters --active 2>/dev/null | grep -c "Id" || echo "0")
    if [ "$clusters" -gt 0 ]; then
        echo "  • EMR Clusters: $clusters active"
        aws emr list-clusters --active 2>/dev/null | grep "Id\|Name" | head -6
    else
        echo "  • EMR Clusters: None active"
    fi
else
    echo "  • AWS CLI not available"
fi
echo ""

# Generate shareable context
echo "📤 Shareable Context (copy/paste for new session):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Working on:"
grep -oE '[A-Z]+-[0-9]+' TODO.md 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//' || echo "No active issues"
echo ""
echo ""

if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Branch: $(git branch --show-current)"
    echo "Commit: $(git rev-parse --short HEAD)"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 NEW SESSION COMMAND (copy this):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract first active issue ID
FIRST_ISSUE=$(grep -oE '[A-Z]+-[0-9]+' ACTIVE.md 2>/dev/null | head -1)
if [ -n "$FIRST_ISSUE" ]; then
    echo "taskflow resume ${FIRST_ISSUE}"
else
    echo "taskflow resume"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
