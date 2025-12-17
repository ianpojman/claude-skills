#!/bin/bash
# TaskFlow Search - Find issues and tasks by keyword

set -e

# Check if search query provided
if [ -z "$1" ]; then
    echo "Usage: ./scripts/taskflow-search.sh <search-query>"
    echo ""
    echo "Examples:"
    echo "  ./scripts/taskflow-search.sh EMR"
    echo "  ./scripts/taskflow-search.sh catalog"
    echo "  ./scripts/taskflow-search.sh \"path fix\""
    exit 1
fi

QUERY="$1"

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                      TASKFLOW SEARCH                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "🔍 Searching for: \"$QUERY\""
echo ""

# Function to search and display results
search_file() {
    local file="$1"
    local label="$2"

    if [ ! -f "$file" ]; then
        return
    fi

    # Search for lines containing the query (case-insensitive)
    # Show issue headers (### lines) that contain the query or are near matches
    local results=$(grep -n -i "$QUERY" "$file" || true)

    if [ -n "$results" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📍 $label"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Extract issue IDs and their context
        echo "$results" | while IFS=: read -r line_num line_text; do
            # Check if this is a header line (### Issue-ID:)
            if echo "$line_text" | grep -q "^###"; then
                issue_id=$(echo "$line_text" | grep -oE '[A-Z]+-[0-9]+' | head -1)
                description=$(echo "$line_text" | sed 's/^###[[:space:]]*//' | sed 's/🔴//' | sed 's/🆕//' | sed 's/⏳//' | sed 's/✅//' | cut -c1-80)
                echo "  • $description"
                echo "    Line $line_num: $file:$line_num"
            else
                # Context line - show snippet
                snippet=$(echo "$line_text" | cut -c1-100)
                echo "  • Line $line_num: $snippet"
            fi
        done

        echo ""
    fi
}

# Search ACTIVE.md
search_file "ACTIVE.md" "ACTIVE.md (Current Sprint)"

# Search BACKLOG.md
search_file "BACKLOG.md" "BACKLOG.md (Future Work)"

# Search session notes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Session Notes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

session_results=$(grep -rn -i "$QUERY" docs/SESSION-*.md 2>/dev/null || true)

if [ -n "$session_results" ]; then
    echo "$session_results" | while IFS=: read -r file line_num line_text; do
        filename=$(basename "$file")
        snippet=$(echo "$line_text" | cut -c1-80)
        echo "  • $filename:$line_num"
        echo "    $snippet"
    done
else
    echo "  (no matches in session notes)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Tip: Use file:line to jump to specific location in your editor"
