---
name: knowledge-capture
description: Captures conversation learnings and updates project documentation. Analyzes session context for discoveries, solutions, gotchas, and architectural insights then updates relevant docs (README, troubleshooting guides, architecture docs, etc.). Works independently or alongside TaskFlow.
---

# Knowledge Capture - Documentation Sync from Conversations

Automatically updates project documentation based on session discoveries and learnings.

## Purpose

**Problem**: Valuable knowledge gets lost in conversations
- Debugging sessions reveal undocumented gotchas
- Architecture decisions made but not written down
- Solutions found but not added to troubleshooting guides
- Performance discoveries not captured

**Solution**: `knowledge-capture` analyzes your session and updates docs

## Quick Commands

```bash
knowledge-capture sync         # Update docs from current session
knowledge-capture discover     # Show what could be documented (dry-run)
knowledge-capture --target=docs/TROUBLESHOOTING.md  # Update specific file
```

## How It Works

### 1. Session Analysis

Scans conversation for:
- **Bugs found** → docs/troubleshooting/
- **Architecture decisions** → docs/architecture/
- **Performance insights** → docs/performance/
- **Setup steps** → README.md, SETUP.md
- **Gotchas & warnings** → Relevant guide sections
- **API changes** → API documentation

### 2. Smart Categorization

Determines where to update:
```
Discovery: "Spark jobs fail with OOM when partition count < 1000"
  → Target: docs/troubleshooting/SPARK_ISSUES.md
  → Section: ## OutOfMemory Errors
  → Content: Add as known issue with solution

Decision: "Using Iceberg instead of Parquet for better schema evolution"
  → Target: docs/architecture/DATA_STORAGE.md
  → Section: ## Storage Format Choice
  → Content: Add rationale and trade-offs

Gotcha: "AWS credentials must be refreshed every 12 hours"
  → Target: SETUP.md
  → Section: ## AWS Configuration
  → Content: Add warning with solution
```

### 3. Documentation Update

Creates structured updates:
```markdown
## [Issue Type] - [Brief Title]

**Discovered**: 2025-11-20
**Context**: [Where this came from]

**Problem**: [What went wrong / what we needed to know]

**Solution**: [How we fixed it / what to do]

**Example**:
```[code/command]```

**Related**: [Links to code, commits, issues]
```

## Commands

### `knowledge-capture sync`

**Interactive mode - recommends updates**

```
Analyzing session...

Found 3 documentation opportunities:

1. Troubleshooting: Spark OOM with low partition counts
   Target: docs/troubleshooting/SPARK_ISSUES.md
   Section: ## OutOfMemory Errors

2. Architecture: Why we chose Iceberg over Parquet
   Target: docs/architecture/DATA_STORAGE.md
   Section: ## Storage Format

3. Setup gotcha: AWS credential refresh requirement
   Target: SETUP.md
   Section: ## AWS Configuration

Apply all? [y/N]: y

✅ Updated docs/troubleshooting/SPARK_ISSUES.md
✅ Updated docs/architecture/DATA_STORAGE.md
✅ Updated SETUP.md

Run "git diff" to review changes before committing.
```

### `knowledge-capture discover`

**Dry-run - shows what could be documented without making changes**

Use when:
- Want to see findings before updating
- Not sure if updates are valuable
- Just exploring what was learned

### `knowledge-capture --target=<file>`

**Update specific documentation file**

```bash
# Only update troubleshooting guide
knowledge-capture --target=docs/troubleshooting/SPARK_ISSUES.md

# Only update README
knowledge-capture --target=README.md
```

## Document Types Supported

### 1. Troubleshooting Guides

**Pattern detected:**
- Error messages in conversation
- "fixed by..." statements
- Root cause analysis

**Update format:**
```markdown
### [Error Type]: [Brief Description]

**Symptoms**: What you'll see
**Cause**: Why it happens
**Solution**: How to fix
**Prevention**: How to avoid

**Example**:
[error log snippet]
[fix command]
```

### 2. Architecture Documentation

**Pattern detected:**
- "Why we chose X over Y"
- Technology selection discussions
- Design trade-offs

**Update format:**
```markdown
## [Component/Decision]

**Decision**: What we chose
**Alternatives**: What we considered
**Rationale**: Why this choice
**Trade-offs**: Pros/cons
**Date**: When decided
```

### 3. Setup/Configuration

**Pattern detected:**
- "Had to configure X"
- "Missing prerequisite Y"
- Installation steps

**Update format:**
```markdown
## [Step/Component]

[Step-by-step instructions]

**Gotcha**: [Common issue]
**Solution**: [How to fix]
```

### 4. Performance Guides

**Pattern detected:**
- "Optimized by..."
- Performance measurements
- Benchmarking results

**Update format:**
```markdown
## [Optimization]

**Before**: [baseline metrics]
**After**: [improved metrics]
**Change**: [what we did]
**Impact**: [improvement %]
```

### 5. API Documentation

**Pattern detected:**
- New endpoints discussed
- API behavior clarified
- Request/response examples

**Update format:**
```markdown
### `[METHOD] /path/to/endpoint`

**Purpose**: What it does
**Request**: [schema/example]
**Response**: [schema/example]
**Example**:
[code]
```

## Smart Features

### Duplicate Detection

Checks existing docs before adding:
- "This OOM error already documented"
- "Similar architecture decision exists"
- Merges with existing section vs creating new

### Context Preservation

Includes:
- Session date
- Related commit SHAs
- File paths mentioned
- Commands used
- Links to relevant code

### Minimal Noise

**Won't document:**
- Trivial findings
- One-off issues
- Already well-documented topics
- Conversational noise

**Will document:**
- Non-obvious solutions
- Gotchas that wasted time
- Important architecture decisions
- Performance insights
- Setup issues that others will hit

## Integration with TaskFlow

**Works independently OR with TaskFlow:**

```bash
# Standalone usage
knowledge-capture sync

# With TaskFlow (updates both)
taskflow capture           # Updates BACKLOG with task context
knowledge-capture sync     # Updates docs with learnings

# Or combined
taskflow capture --with-docs
  → Updates BACKLOG.md with task progress
  → Updates project docs with learnings
```

## File Structure

Expects/creates:
```
docs/
├── troubleshooting/
│   ├── SPARK_ISSUES.md
│   ├── AWS_ISSUES.md
│   └── API_ISSUES.md
├── architecture/
│   ├── DATA_STORAGE.md
│   ├── API_DESIGN.md
│   └── DEPLOYMENT.md
├── performance/
│   └── OPTIMIZATIONS.md
└── INDEX.md

README.md
SETUP.md
```

Auto-creates missing files with templates.

## Configuration

Optional `.knowledge-capture.json`:

```json
{
  "targets": {
    "troubleshooting": "docs/troubleshooting/",
    "architecture": "docs/architecture/",
    "setup": "SETUP.md",
    "readme": "README.md"
  },
  "autoCommit": false,
  "requireApproval": true,
  "minImportance": "medium"
}
```

## Example Session

**Conversation:**
```
User: "Help debug this Spark OOM error"
[... debugging ...]
Assistant: "Found the issue - partition count was too low.
            Setting spark.sql.shuffle.partitions=2000 fixed it.
            OOMs happen when < 1000 partitions with large datasets."
```

**knowledge-capture sync detects:**
```
📚 Documentation Opportunity Detected

Type: Troubleshooting
Title: Spark OOM with Low Partition Counts
Target: docs/troubleshooting/SPARK_ISSUES.md

Proposed Update:
─────────────────────────────────────────
### OutOfMemory: Insufficient Partition Count

**Symptoms**:
- Spark executors crash with OutOfMemoryError
- Jobs succeed with small data, fail with production data

**Cause**:
Too few shuffle partitions (<1000) for large datasets

**Solution**:
```bash
spark.conf.set("spark.sql.shuffle.partitions", "2000")
```

**Prevention**:
Rule of thumb: 1 partition per 128MB of data

**Session**: 2025-11-20
**Related**: [commit abc123]
─────────────────────────────────────────

Add this to docs/troubleshooting/SPARK_ISSUES.md? [Y/n]:
```

## Benefits

✅ **Knowledge preserved** - Nothing gets lost
✅ **Zero manual work** - Automatic extraction
✅ **Team benefit** - Others learn from your debugging
✅ **Better docs** - Always up-to-date
✅ **Searchable** - Findings easy to find later

## When to Use

**After sessions involving:**
- Debugging complex issues
- Making architecture decisions
- Finding performance bottlenecks
- Discovering setup gotchas
- Clarifying API behavior
- Learning new parts of codebase

**Don't use for:**
- Routine tasks
- No new learnings
- Trivial changes
- Conversation with no technical insights

---

*Automatically documents your discoveries so they're never lost.*
