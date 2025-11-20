#!/bin/bash
# TaskFlow Validate - Check link integrity

set -e


echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                    TASKFLOW LINK VALIDATION                          ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo

ERRORS=0

echo "Checking archive structure..."
if [ -f "docs/strategy/archived/2025-11/COMPLETED.md" ]; then
    echo "  ✅ Archive file exists"
else
    echo "  ❌ Archive file missing: docs/strategy/archived/2025-11/COMPLETED.md"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking ACTIVE.md references..."
if grep -q "docs/strategy/archived" ACTIVE.md; then
    echo "  ✅ ACTIVE.md references archive"
else
    echo "  ❌ ACTIVE.md missing archive reference"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking BACKLOG.md references..."
if grep -q "archived/2025-11/COMPLETED.md" BACKLOG.md; then
    echo "  ✅ BACKLOG.md references archive"
else
    echo "  ❌ BACKLOG.md missing archive reference"
    ERRORS=$((ERRORS + 1))
fi
echo

echo "Checking for broken links in ACTIVE.md..."
# Check docs/active/ references
for file in $(grep -oP 'docs/active/[^)]+\.md' ACTIVE.md 2>/dev/null | sort -u); do
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
