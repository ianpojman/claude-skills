#!/bin/bash
# TaskFlow Validate - Check link integrity

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TASKFLOW_ROOT=$("$SCRIPT_DIR/taskflow-resolve-root.sh" "$PROJECT_ROOT")

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    TASKFLOW LINK VALIDATION                          ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo

ERRORS=0

echo "Checking archive structure..."
if [ -f "$TASKFLOW_ROOT/docs/strategy/archived/2025-11/COMPLETED.md" ]; then
    echo "  ✅ Archive file exists"
else
    echo "  ❌ Archive file missing: $TASKFLOW_ROOT/docs/strategy/archived/2025-11/COMPLETED.md"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking $TASKFLOW_ROOT/ACTIVE.md references..."
if grep -q "$TASKFLOW_ROOT/docs/strategy/archived" $TASKFLOW_ROOT/ACTIVE.md; then
    echo "  ✅ $TASKFLOW_ROOT/ACTIVE.md references archive"
else
    echo "  ❌ $TASKFLOW_ROOT/ACTIVE.md missing archive reference"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking $TASKFLOW_ROOT/BACKLOG.md references..."
if grep -q "archived/2025-11/COMPLETED.md" $TASKFLOW_ROOT/BACKLOG.md; then
    echo "  ✅ $TASKFLOW_ROOT/BACKLOG.md references archive"
else
    echo "  ❌ $TASKFLOW_ROOT/BACKLOG.md missing archive reference"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking for broken links in $TASKFLOW_ROOT/ACTIVE.md..."
# Check $TASKFLOW_ROOT/docs/active/ references
for file in $(grep -oP '$TASKFLOW_ROOT/docs/active/[^)]+\.md' $TASKFLOW_ROOT/ACTIVE.md 2>/dev/null | sort -u); do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (referenced but missing)"
        ERRORS=$((ERRORS + 1))
    fi
done
echo

if [ $ERRORS -eq 0 ]; then
    echo "✅ All validations passed!"
    exit 0
else
    echo "❌ Found $ERRORS error(s)"
    exit 1
fi
