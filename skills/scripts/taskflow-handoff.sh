#!/bin/bash
# TaskFlow Handoff - Save session state with optional naming
# Automatically captures session and creates records for new tasks

set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 1

# Create handoff directory
mkdir -p docs/handoff
mkdir -p docs/active

# Get session name (optional argument)
SESSION_NAME="$1"
CAPTURE_SUMMARY="$2"

# Step 1: Auto-capture current session state if summary provided
if [ -n "$CAPTURE_SUMMARY" ]; then
    CAPTURE_SCRIPT="$HOME/.claude/skills/scripts/taskflow-capture.sh"
    if [ -x "$CAPTURE_SCRIPT" ] && [ -f "ACTIVE.md" ]; then
        "$CAPTURE_SCRIPT" "$CAPTURE_SUMMARY" >/dev/null 2>&1 || true
        echo "📝 Captured session state to ACTIVE.md"
    fi
fi

# Step 2: Get session info
SESSION_SCRIPT="$HOME/.claude/skills/scripts/taskflow-session.sh"
CURRENT_TASK=""
ALL_TASKS=()

if [ -x "$SESSION_SCRIPT" ]; then
    # Get all tasks from session
    CURRENT_TASK=$("$SESSION_SCRIPT" get-current)
    # Portable alternative to mapfile (works on Bash 3.2+)
    while IFS= read -r task; do
        [ -n "$task" ] && ALL_TASKS+=("$task")
    done < <("$SESSION_SCRIPT" get-all)
else
    # Fallback to legacy
    if [ -f ".taskflow-current" ]; then
        CURRENT_TASK=$(cat .taskflow-current)
        ALL_TASKS=("$CURRENT_TASK")
    fi
fi

# Step 3: Ensure all tasks have task files created
for TASK_ID in "${ALL_TASKS[@]}"; do
    TASK_FILE="docs/active/${TASK_ID}.md"

    if [ ! -f "$TASK_FILE" ]; then
        echo "⚠️  Creating missing task file: $TASK_ID"

        # Extract task title from ACTIVE.md if possible
        TASK_TITLE=$(grep "^### ${TASK_ID}:" ACTIVE.md 2>/dev/null | sed "s/^### ${TASK_ID}: //" | head -1 || echo "Unknown Task")

        # Create task file
        cat > "$TASK_FILE" <<TASKEOF
# ${TASK_ID}: ${TASK_TITLE}

**Status**: in_progress
**Created**: $(date +"%Y-%m-%d %H:%M")
**Auto-generated**: Created during handoff

## Description

${TASK_TITLE}

## Tasks

- [ ] TODO (add details)

## Notes

(Auto-created during session handoff)

TASKEOF

        echo "   ✓ Created: $TASK_FILE"

        # Add to ACTIVE.md if not already there
        if ! grep -q "^### ${TASK_ID}:" ACTIVE.md 2>/dev/null; then
            # Find the Active Tasks section and add the task
            if grep -q "^## 🚀 Active Tasks" ACTIVE.md; then
                sed -i.bak "/^## 🚀 Active Tasks/a\\
\\
### ${TASK_ID}: ${TASK_TITLE}\\
[Details →](docs/active/${TASK_ID}.md)
" ACTIVE.md
                echo "   ✓ Added to ACTIVE.md"
            fi
        fi
    fi
done

echo ""

# Auto-generate name if not provided
if [ -z "$SESSION_NAME" ]; then
    TIMESTAMP=$(date +%Y-%m-%d-%H%M)
    if [ -n "$CURRENT_TASK" ]; then
        SESSION_NAME="${CURRENT_TASK}-${TIMESTAMP}"
    else
        SESSION_NAME="${TIMESTAMP}"
    fi
fi

# Sanitize session name (lowercase, replace spaces with hyphens)
SESSION_NAME=$(echo "$SESSION_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

HANDOFF_FILE="docs/handoff/${SESSION_NAME}.md"
METADATA_FILE="docs/handoff/.sessions.json"

# Initialize metadata file if it doesn't exist
if [ ! -f "$METADATA_FILE" ]; then
    echo '{"sessions":[]}' > "$METADATA_FILE"
fi

# Generate handoff content
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$HANDOFF_FILE" <<EOF
# Session Handoff: $SESSION_NAME

**Created**: $TIMESTAMP
**Branch**: $(git branch --show-current 2>/dev/null || echo "N/A")
**Commit**: $(git rev-parse --short HEAD 2>/dev/null || echo "N/A")

---

## 🚀 Resume This Session

\`\`\`bash
/tfresume $SESSION_NAME
\`\`\`

---

## Tasks Worked On

EOF

# All tasks in session
TASK_IDS_LIST=""
if [ ${#ALL_TASKS[@]} -gt 0 ]; then
    for TASK_ID in "${ALL_TASKS[@]}"; do
        TASK_FILE="docs/active/${TASK_ID}.md"
        if [ -f "$TASK_FILE" ]; then
            TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${TASK_ID}: //" || echo "Unknown")
            TASK_STATUS=$(grep "^\*\*Status\*\*:" "$TASK_FILE" | head -1 | sed 's/\*\*Status\*\*: //' || echo "In Progress")

            CURRENT_MARKER=""
            if [ "$TASK_ID" = "$CURRENT_TASK" ]; then
                CURRENT_MARKER=" ← **CURRENT**"
            fi

            cat >> "$HANDOFF_FILE" <<EOF
### $TASK_ID: $TASK_TITLE$CURRENT_MARKER

**Status**: $TASK_STATUS
**Details**: [docs/active/${TASK_ID}.md](docs/active/${TASK_ID}.md)

EOF
            TASK_IDS_LIST="$TASK_IDS_LIST $TASK_ID"
        fi
    done
else
    echo "No tasks tracked in this session" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
fi

TASK_IDS_LIST=$(echo "$TASK_IDS_LIST" | xargs)  # Trim whitespace

# Running processes
cat >> "$HANDOFF_FILE" <<EOF
## Running Processes

EOF

CLUSTER_IDS=""
if command -v aws &> /dev/null; then
    EMR_CLUSTERS=$(aws emr list-clusters --active 2>/dev/null || echo "")
    if echo "$EMR_CLUSTERS" | grep -q "Id"; then
        echo "### EMR Clusters" >> "$HANDOFF_FILE"
        echo "" >> "$HANDOFF_FILE"
        echo "$EMR_CLUSTERS" | grep -E "Id|Name|Status" >> "$HANDOFF_FILE"
        echo "" >> "$HANDOFF_FILE"
        CLUSTER_IDS=$(echo "$EMR_CLUSTERS" | grep -oE 'j-[A-Z0-9]+' | head -3 | tr '\n' ',' | sed 's/,$//')
    else
        echo "No active EMR clusters" >> "$HANDOFF_FILE"
        echo "" >> "$HANDOFF_FILE"
    fi
else
    echo "AWS CLI not available" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
fi

# Git status
cat >> "$HANDOFF_FILE" <<EOF
## Git Status

EOF

if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "✅ Clean working directory" >> "$HANDOFF_FILE"
else
    echo "⚠️ Uncommitted changes:" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
    echo "\`\`\`" >> "$HANDOFF_FILE"
    git status --short >> "$HANDOFF_FILE"
    echo "\`\`\`" >> "$HANDOFF_FILE"
fi
echo "" >> "$HANDOFF_FILE"

# Next steps
cat >> "$HANDOFF_FILE" <<EOF
## Next Steps

EOF

if [ -n "$CLUSTER_IDS" ]; then
    echo "1. Check cluster status:" >> "$HANDOFF_FILE"
    IFS=',' read -ra CLUSTERS <<< "$CLUSTER_IDS"
    for CLUSTER_ID in "${CLUSTERS[@]}"; do
        echo "   - \`aws emr describe-cluster --cluster-id $CLUSTER_ID\`" >> "$HANDOFF_FILE"
    done
    echo "" >> "$HANDOFF_FILE"
fi

if [ ${#ALL_TASKS[@]} -gt 1 ]; then
    echo "2. The \`/tfresume\` command will let you choose which task to continue" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
elif [ -n "$CURRENT_TASK" ]; then
    echo "2. Resume will continue: \`$CURRENT_TASK\`" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
fi

# Recent session notes
if [ -f "ACTIVE.md" ]; then
    RECENT_NOTES=$(grep -A 20 "### 📅 Session Notes" ACTIVE.md | head -20 || echo "")
    if [ -n "$RECENT_NOTES" ]; then
        cat >> "$HANDOFF_FILE" <<EOF

## Recent Session Notes

$RECENT_NOTES

EOF
    fi
fi

# Summary of tasks at the bottom
cat >> "$HANDOFF_FILE" <<EOF

---

## Summary

EOF

if [ ${#ALL_TASKS[@]} -gt 0 ]; then
    echo "**Tasks worked on in this session:**" >> "$HANDOFF_FILE"
    echo "" >> "$HANDOFF_FILE"
    for TASK_ID in "${ALL_TASKS[@]}"; do
        TASK_FILE="docs/active/${TASK_ID}.md"
        if [ -f "$TASK_FILE" ]; then
            TASK_TITLE=$(grep -m 1 "^# " "$TASK_FILE" | sed 's/^# //' | sed "s/${TASK_ID}: //" || echo "Unknown")
            echo "- **$TASK_ID**: $TASK_TITLE" >> "$HANDOFF_FILE"
        fi
    done
    echo "" >> "$HANDOFF_FILE"
fi

# Final resume command - LAST THING IN FILE
cat >> "$HANDOFF_FILE" <<EOF

---

## 🚀 Resume This Session

\`\`\`bash
/tfresume $SESSION_NAME
\`\`\`

EOF

# Update metadata
# Create task IDs array for JSON
TASK_IDS_JSON=""
if [ ${#ALL_TASKS[@]} -gt 0 ]; then
    TASK_IDS_JSON=$(printf ',"%s"' "${ALL_TASKS[@]}")
    TASK_IDS_JSON="[${TASK_IDS_JSON:1}]"  # Remove leading comma and wrap in brackets
else
    TASK_IDS_JSON="[]"
fi

# Create new session entry
SESSION_ENTRY=$(cat <<EOF
{
  "name": "$SESSION_NAME",
  "timestamp": "$ISO_TIMESTAMP",
  "tasks": $TASK_IDS_JSON,
  "current_task": "${CURRENT_TASK:-null}",
  "status": "active",
  "processes": [$(echo "$CLUSTER_IDS" | sed 's/\([^,]*\)/"\1"/g')],
  "handoff_file": "$HANDOFF_FILE"
}
EOF
)

# Add to sessions array using jq if available, otherwise append
if command -v jq &> /dev/null; then
    TMP=$(mktemp)
    jq ".sessions += [$SESSION_ENTRY]" "$METADATA_FILE" > "$TMP" && mv "$TMP" "$METADATA_FILE"
else
    # Fallback: simple append (less robust but works)
    echo "  (jq not available, metadata not updated)"
fi

# Output to console
echo "✅ Session handoff saved"
echo ""
echo "📄 Details saved to: $HANDOFF_FILE"
if [ -n "$TASK_IDS_LIST" ]; then
    echo "📋 Tasks: $TASK_IDS_LIST"
fi
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📌 To resume in a new session, paste this:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# The ONE command to paste
if [ ${#ALL_TASKS[@]} -gt 1 ]; then
    echo "  /tfresume $SESSION_NAME"
elif [ -n "$CURRENT_TASK" ]; then
    echo "  /tfresume $SESSION_NAME"
else
    echo "  /tfresume $SESSION_NAME"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
