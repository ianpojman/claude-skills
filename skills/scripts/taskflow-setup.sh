#!/bin/bash
# TaskFlow Setup - Initialize TaskFlow for a new project
# Creates external directory structure with starter files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")
PROJECT_NAME=$(basename "$PROJECT_ROOT")

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    TASKFLOW SETUP                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Project: $PROJECT_NAME"
echo "TaskFlow Root: $TASKFLOW_ROOT"
echo ""

# Check if already initialized
if [ -f "$TASKFLOW_ROOT/ACTIVE.md" ]; then
    echo "✅ TaskFlow already initialized for this project"
    echo ""
    echo "Files:"
    ls -la "$TASKFLOW_ROOT/"
    exit 0
fi

# Create ACTIVE.md
cat > "$TASKFLOW_ROOT/ACTIVE.md" <<'EOF'
# Active Tasks

## 🚀 Active Tasks

<!-- Add tasks here with format: ### TASK-ID: Description -->

## Summary

- Total: 0 tasks
- In Progress: 0
- Completed: 0

---

*Last updated: $(date +%Y-%m-%d)*
EOF

# Create BACKLOG.md
cat > "$TASKFLOW_ROOT/BACKLOG.md" <<'EOF'
# Backlog

## Categories

<!-- Organize future work by category -->

### Category 1

- [ ] Future task 1
- [ ] Future task 2

---

*TaskFlow backlog for project*
EOF

echo "✅ TaskFlow initialized!"
echo ""
echo "Created:"
echo "  • $TASKFLOW_ROOT/ACTIVE.md"
echo "  • $TASKFLOW_ROOT/BACKLOG.md"
echo "  • $TASKFLOW_ROOT/docs/active/"
echo "  • $TASKFLOW_ROOT/docs/handoff/"
echo ""
echo "Quick commands:"
echo "  /tfs              - Show status"
echo "  /tfstart TASK-ID  - Start a task"
echo "  /tfhandoff        - Save session state"
echo ""
echo "Note: TaskFlow files are stored externally in ~/.taskflow/"
echo "      They are NOT in your project's git repository."
