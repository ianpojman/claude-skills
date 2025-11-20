#!/bin/bash
# TaskFlow Capture - Save current session state to ACTIVE.md (non-interactive)

set -e

# Non-interactive mode: accept summary as argument
if [ -z "$1" ]; then
    echo "Usage: ./scripts/taskflow-capture.sh \"session summary\""
    echo ""
    echo "Example:"
    echo "  ./scripts/taskflow-capture.sh \"Fixed ETL-001. Next: test hour 23 validation\""
    exit 1
fi

SESSION_DATE=$(date +%Y-%m-%d)
SESSION_SUMMARY="$1"

# Append to ACTIVE.md
cat >> ACTIVE.md <<EOF

### 📅 Session Notes - ${SESSION_DATE}

${SESSION_SUMMARY}

---
EOF

echo "✅ Session summary added to ACTIVE.md"
echo ""
echo "Summary:"
echo "  ${SESSION_SUMMARY}"
