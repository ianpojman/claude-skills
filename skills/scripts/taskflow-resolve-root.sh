#!/bin/bash
# Resolve TaskFlow root directory for a project
# Usage: taskflow-resolve-root.sh [PROJECT_ROOT]
# Returns: path to ~/.claude/projects/{slug}/

set -e

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROJECT_SLUG=$(basename "$PROJECT_ROOT")
TASKFLOW_ROOT="$HOME/.taskflow/$PROJECT_SLUG"

# Auto-create directory structure if needed
if [ ! -d "$TASKFLOW_ROOT" ]; then
    mkdir -p "$TASKFLOW_ROOT/docs/active"
    mkdir -p "$TASKFLOW_ROOT/docs/backlog"
    mkdir -p "$TASKFLOW_ROOT/docs/handoff"
    mkdir -p "$TASKFLOW_ROOT/docs/session-notes"
fi

echo "$TASKFLOW_ROOT"
