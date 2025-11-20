#!/bin/bash
# Minimal status - no fancy formatting

cd "$HOME/Projects/predictive_24_spark" || exit 1

# Count tasks
total=$(grep -c "^###" ACTIVE.md 2>/dev/null || echo 0)
completed=$(grep -c "✅" ACTIVE.md 2>/dev/null || echo 0)
in_progress=$(grep -c "⏳ IN PROGRESS" ACTIVE.md 2>/dev/null || echo 0)

# Git info
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
commit=$(git rev-parse --short HEAD 2>/dev/null)

# Token counts
active_tokens=$(wc -c < ACTIVE.md | awk '{print int($1/4000)}')
backlog_tokens=$(wc -c < BACKLOG.md | awk '{print int($1/4000)}')

echo "📊 $total tasks | $in_progress active | $completed done"
echo "📁 $branch @ $commit"  
echo "🔢 ACTIVE: ${active_tokens}K | BACKLOG: ${backlog_tokens}K"
