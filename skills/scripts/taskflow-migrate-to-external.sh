#!/bin/bash
# Migrate TaskFlow files from in-project to external ~/.taskflow/ directory
# Usage: taskflow-migrate-to-external.sh [PROJECT_ROOT]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

echo "Migrating TaskFlow files..."
echo "  From: $PROJECT_ROOT"
echo "  To:   $TASKFLOW_ROOT"
echo ""

# Files to migrate
FILES_TO_MIGRATE=(
    "ACTIVE.md"
    "BACKLOG.md"
    ".taskflow-session.json"
    ".taskflow-current"
)

# Directories to migrate
DIRS_TO_MIGRATE=(
    "docs/active"
    "docs/backlog"
    "docs/handoff"
    "docs/session-notes"
)

migrated=0

# Migrate individual files
for file in "${FILES_TO_MIGRATE[@]}"; do
    src="$PROJECT_ROOT/$file"
    dst="$TASKFLOW_ROOT/$file"
    if [ -f "$src" ]; then
        if [ -f "$dst" ]; then
            echo "  SKIP: $file (already exists in destination)"
        else
            cp "$src" "$dst"
            echo "  MOVED: $file"
            ((migrated++))
        fi
    fi
done

# Migrate directories
for dir in "${DIRS_TO_MIGRATE[@]}"; do
    src="$PROJECT_ROOT/$dir"
    dst="$TASKFLOW_ROOT/$dir"
    if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
        mkdir -p "$dst"
        # Copy contents, not directory itself
        for item in "$src"/*; do
            if [ -e "$item" ]; then
                name=$(basename "$item")
                if [ -e "$dst/$name" ]; then
                    echo "  SKIP: $dir/$name (already exists)"
                else
                    cp -r "$item" "$dst/"
                    echo "  MOVED: $dir/$name"
                    ((migrated++))
                fi
            fi
        done
    fi
done

echo ""
echo "Migration complete. $migrated items moved."
echo ""
echo "Next steps:"
echo "  1. Verify files in: $TASKFLOW_ROOT"
echo "  2. Remove old files from git (optional):"
echo "     git rm ACTIVE.md BACKLOG.md"
echo "     git rm -r docs/active docs/backlog docs/handoff docs/session-notes"
echo "  3. Update .gitignore if keeping local copies"
