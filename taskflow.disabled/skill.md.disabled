---
name: taskflow
description: Token-efficient task and documentation management. Manages ACTIVE.md, BACKLOG.md, session resumption, task capture, and handoff generation. Keeps token usage under budget across the three-tier system.
---

# TaskFlow - Token-Efficient Task Management

Manages project tasks/docs with automatic archival and token optimization.

## 🚀 Startup Greeting

When you invoke this skill, you'll see:

```
TaskFlow Active
Last operations:
  • analyze: 2 days ago ⚠️ (recommended: weekly)
  • compact: 15 days ago ❌ (OVERDUE - run when BACKLOG > 10K)
  • capture: never run ℹ️  (use after debugging sessions)
  • validate: 7 days ago ✅ (good)

Current status:
  • BACKLOG.md: 21.8K tokens (11.8K over budget)
  • TODO.md: 1.1K tokens ✅

💡 Recommendation: Run "taskflow compact" (BACKLOG 2x over budget)

Available commands: analyze, compact, sync, capture, new, validate
```

**Tracks** last run dates in `.taskflow/history.json`
**Recommends** overdue operations based on:
- `compact`: When BACKLOG > 10K tokens
- `analyze`: Weekly recommended
- `validate`: After any archive/compact operation
- `capture`: After investigation/debugging sessions

## Quick Commands

**IMPORTANT**: When user types just `taskflow` with no arguments, run `~/.claude/scripts/taskflow.sh` which shows:
- First 5 active tasks with status emojis
- Task count and token status
- Git context
- Help hint

This is the main entry point and should be the default when user says "taskflow" or asks about TaskFlow status.

```bash
taskflow            # Show active tasks (DEFAULT - compact view)
                    # Script: ~/.claude/scripts/taskflow.sh
                    # First 5 tasks + status + git context

taskflow init       # Session resumption - prime AI context
                    # Script: ~/.claude/scripts/taskflow-init.sh
                    # Generates context primer for new AI sessions

taskflow status     # Quick one-line status check
                    # Script: ~/.claude/scripts/taskflow-status.sh
                    # Shows: tasks, branch, tokens

taskflow capture SUMMARY    # Capture session notes
                            # Script: ~/.claude/scripts/taskflow-capture.sh "summary text"
                            # Non-interactive: pass summary as argument

taskflow handoff [SUMMARY]  # End session handoff
                            # Script: ~/.claude/scripts/taskflow-handoff.sh "summary"
                            # Optional: pass summary or use --no-capture to skip

taskflow analyze    # Token usage + archival candidates
                    # Script: ~/.claude/scripts/taskflow-analyze.sh

taskflow validate   # Check link integrity
                    # Script: ~/.claude/scripts/taskflow-validate.sh

taskflow search QUERY    # Search issues by keyword
                         # Script: ~/.claude/scripts/taskflow-search.sh "keyword"
                         # Searches ACTIVE.md, BACKLOG.md, session notes

taskflow list            # List all active tasks with status
                         # Script: ~/.claude/scripts/taskflow-list.sh
                         # Shows issue IDs, status emojis, descriptions

taskflow resume TASK-ID  # Resume work on specific task
                         # Script: ~/.claude/scripts/taskflow-resume.sh "TASK-ID"
                         # Shows full context, related docs, session notes
```

**All scripts available at:**
- `~/.claude/scripts/taskflow-init.sh` - Session resumption
- `~/.claude/scripts/taskflow-status.sh` - Quick status
- `~/.claude/scripts/taskflow-capture.sh` - Interactive updates
- `~/.claude/scripts/taskflow-handoff.sh` - Handoff generator
- `~/.claude/scripts/taskflow-analyze.sh` - Token analysis
- `~/.claude/scripts/taskflow-validate.sh` - Link validation
- `~/.claude/scripts/taskflow-search.sh` - Search issues by keyword
- `~/.claude/scripts/taskflow-list.sh` - List all active tasks
- `~/.claude/scripts/taskflow-resume.sh` - Resume specific task

## System Structure

```
ACTIVE.md (2K limit)           → Current sprint tasks + session notes
BACKLOG.md (10K limit)         → Future work + detailed plans
LINKING-STANDARD.md            → Documentation linking conventions
docs/active/ (5K each)         → Current sprint details
docs/completed/YYYY-MM/        → Archived (not loaded)
docs/strategy/archived/        → Old backlog items
```

## Operations

### `taskflow init`
**Session Resumption** - Start new AI session
- Runs `./scripts/taskflow-init.sh`
- Shows current status
- Generates context primer prompt
- Lists active tasks and git context

**Use at:** Start of new session

### `taskflow status`
**Quick Check** - One-line status
- Runs `./scripts/taskflow-status.sh`
- Format: `📊 N active | branch@commit | ACTIVE Ntok | BACKLOG Ntok`

**Use anytime** for quick check

### `taskflow capture "summary"`
**Capture Session Notes** - Write to ACTIVE.md
- Runs `./scripts/taskflow-capture.sh "summary text"`
- Non-interactive mode for Claude Code
- Adds timestamped session note

**Example:**
```bash
./scripts/taskflow-capture.sh "Fixed ETL-001, investigated CAT-004. Next: test hour 23"
```

**Use during/end session** to record progress

### `taskflow handoff ["summary"]`
**Session End** - Generate handoff (optionally capture first)
- Runs `./scripts/taskflow-handoff.sh`
- With argument: captures summary first, then generates handoff
- Without argument: just generates handoff (shows tip)
- Use `--no-capture` to skip capture entirely

**Examples:**
```bash
# Capture + handoff
./scripts/taskflow-handoff.sh "Fixed ETL-001, started CAT-004"

# Just handoff (no capture)
./scripts/taskflow-handoff.sh --no-capture
```

**Shows:** Active issues, git context, running processes, shareable context

**Use at end of session**

### `taskflow analyze`
**Token Analysis**
- Runs `./scripts/taskflow-analyze.sh`
- Shows token usage for ACTIVE.md and BACKLOG.md
- Lists archival candidates (completed items)

**Output:**
```
ACTIVE.md: 1.8K ✅ | BACKLOG.md: 31K ❌ (21K over)
Archive candidates: VER-001 Phase 1 (8K), CAT-003 (4K)
```

### `taskflow validate`
**Link Integrity**
- Runs `./scripts/taskflow-validate.sh`
- Checks archive structure
- Validates cross-references
- Finds broken links
- Validate link integrity

**Result:** BACKLOG.md: 31K → 9K (22K saved)

### `taskflow sync`

**Two modes:**

**1. Status Sync** (default):
- Compare status: TODO.md ↔ BACKLOG.md
- Detect mismatches
- Suggest fixes

**Output:**
```
✅ 12 synced | ⚠️ 2 mismatches
CAT-003: TODO says "Ready", BACKLOG says "✅ Complete"
```

### `taskflow capture`

**Automatically creates/updates BACKLOG items from conversation context**

- Reviews current conversation
- Identifies discoveries, solutions, new issues
- **Creates new BACKLOG items** for new problems found
- **Updates existing items** with implementation notes
- Adds discoveries, blockers, alternative approaches
- Preserves conversation insights before session ends

**Use when:**
- Finished debugging/investigating
- Found new issues during work
- Want to preserve session insights
- Before ending a productive session

### `taskflow resume TASK-ID`
**Resume Work on Specific Task**
- Runs `./scripts/taskflow-resume.sh TASK-ID`
- Extracts full task context from ACTIVE.md and BACKLOG.md
- Shows detailed documentation from docs/active/ if available
- Lists related session notes
- Displays current git context

**Example:**
```bash
./scripts/taskflow-resume.sh VAL-001
```

**Output:**
```
╔══════════════════════════════════════════════════════════════════════╗
║                      RESUME TASK: VAL-001                            ║
╚══════════════════════════════════════════════════════════════════════╝

✅ Found in ACTIVE.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
### VAL-001: Task Description
**Status**: ⏳ In progress
**Details**: Full task context...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Found detailed documentation:
📄 docs/active/VAL-001-details.md
...

🔧 Current Git Context
  Branch: feature/...
  Commit: abc1234
```

**Use when:**
- Picking up work on a specific task
- Need full context for a task ID
- Starting work after a break
- Another developer mentioned a task ID

**Benefits:**
- ✅ Instant access to full task context
- ✅ Shows all related documentation
- ✅ Links to session notes
- ✅ Current git state for reference

### `taskflow handoff`

**Creates session handoff for work-in-progress that a NEW Claude session can pick up**

- Creates concise SESSION-*.md summary (1-2K tokens)
- Updates TODO.md with IN PROGRESS issue ID
- Includes current state (cluster IDs, step IDs, validation commands)
- Links to detailed context in BACKLOG.md

**Handoff format in TODO.md:**
```markdown
### ISSUE-ID: Task Name (IN PROGRESS)
**Session**: [Summary Link](docs/SESSION-*.md)
**Status**: ⏳ Current state description

**What was done**: Brief list of completed work + commits

**Current State**:
- Cluster/Job IDs, timestamps
- What's running and when it started

**What needs doing**:
1. Next steps with exact commands
2. Validation criteria
3. Expected outcomes

**Quick Status Check**:
```bash
# Commands a new agent can run immediately
```

**Detailed Context**: Links to BACKLOG + session summary
```

**Use when:**
- Long-running job needs monitoring (EMR, builds, tests)
- Context window getting full, need to continue later
- Want another agent to pick up seamlessly
- Session ending but work incomplete

**Pattern ensures:**
- ✅ New agent reads TODO.md → sees IN PROGRESS task
- ✅ Immediate context: what's running, how to check status
- ✅ Deep context: session summary + BACKLOG details
- ✅ Clear next steps: exact commands to run
- ✅ Validation criteria: how to know if it worked

**Output:**
```
Analyzing conversation context...

Found 2 updates + 1 new issue:

UPDATE CAT-003:
  • Discovery: Static config modification was root cause
  • Fix: Removed mutation in CatalogMetadataTableManager
  • Files: src/main/scala/.../CatalogMetadataTableManager.scala

UPDATE SPARSE-001:
  • Complete audit: 7 files had sampling defaults
  • Original fix only addressed 2/7 files
  • All files now verified with grep

CREATE TASKFLOW-001: Documentation Management System
  • Token-efficient task management skill
  • 3-tier archival: TODO → active → completed
  • Saved 3.3K tokens in first run

Apply updates? [y/N]: y

✅ Updated 2 items
✅ Created 1 new item
✅ Synced TODO.md
```

**Smart behavior:**
- Detects item IDs mentioned in conversation (e.g., "CAT-003")
- Extracts code file paths, line numbers, commit SHAs
- Identifies error messages, root causes, solutions
- Recognizes new problems → suggests new BACKLOG items
- Preserves technical details (commands, configs, findings)

**Rich context for future agents:**

Captures comprehensive context so another agent can understand the issue:

```markdown
## CAT-003: Catalog Auto-Update Failing

### Investigation History

#### Session 2025-11-20 (Context captured via taskflow)

**Problem**: Athena catalog metadata table not updating after EMR jobs

**Root Cause Discovered**:
- Static config modification in `CatalogMetadataTableManager.scala:145`
- Code was mutating `spark.sql.catalog.default` globally
- Caused downstream jobs to fail with catalog not found errors

**Files Modified**:
- `src/main/scala/.../CatalogMetadataTableManager.scala:145-167`
- Removed: `spark.conf.set("spark.sql.catalog.default", ...)`
- Solution: Use session-scoped catalog access instead

**Commits**: 1825c62b, ca4517e8, 2ad5344f

**Testing**:
- Command: `./test/scripts/e2e-validation.sh 23`
- Expected: Catalog auto-updates without manual repair
- Validation: Pending EMR job completion

**Related Context**:
- Error logs: See EMR stderr at `/tmp/cat003-validation.log`
- Original issue: docs/active/CAT-003-catalog-auto-update.md
- Prior attempt: Incomplete fix in commit 9b52f2f4 (only fixed 2 files)

**Key Learning**: Always grep entire codebase for similar patterns when fixing defaults
```

**Benefits**:
- Future agent sees full investigation trail
- No re-discovery of known issues
- Clear testing instructions
- Links to relevant files/commits
- Error logs and commands preserved

### `taskflow new <ID> <title>`
- Create BACKLOG.md entry (full template)
- Add TODO.md summary with link
- Optional: Create docs/active/ file

### `taskflow validate`
- Check all links in TODO/BACKLOG
- Find broken references
- Detect orphaned files

## Token Budgets

- **TODO.md**: 2K (always loaded)
- **BACKLOG.md**: 10K (context loaded)
- **docs/active/***: 5K each (on-demand)
- **docs/completed/***: ∞ (never auto-loaded)

## Archival Rules

**Move when:**
- Status shows ✅ or "Complete"
- Item not referenced in 30+ days
- File exists in docs/active/ but TODO shows "Done"

**Archive to:**
- BACKLOG completed → `docs/strategy/archived/YYYY-MM/`
- docs/active/ done → `docs/completed/YYYY-MM/`

**Always:**
- Update TODO.md links
- Regenerate INDEX.md
- Validate no broken refs

## Token Counting

Simple heuristic: **1 token ≈ 4 chars**
```bash
wc -c file.md | awk '{print int($1/4) "K"}'
```

## Integration

**Works with:**
- **ClaudeFlow**: Autonomous task execution (`claudeflow` or `taskflow flow`)
- Existing docs/strategy/README.md process
- Three-tier system (TODO → active → completed)
- Git workflow (no temp files)

**ClaudeFlow Integration**:
TaskFlow tracks high-level tasks and documentation, ClaudeFlow executes multi-stage tasks autonomously.

```bash
# Create TaskFlow issue
taskflow new REF-001 "Refactor auth module"

# Create ClaudeFlow task for autonomous execution
claudeflow create refactor_auth "REF-001: Refactor auth"
# Links to TaskFlow issue during setup

# Run autonomously
claudeflow start refactor_auth 20
# Claude automatically updates ACTIVE.md and captures progress

# Alternative: Use via TaskFlow command
taskflow flow create my_task "Task description"
taskflow flow start my_task 15
```

**Respects:**
- No attribution in commits
- Temp* prefix for throwaway code
- README.md project instructions

## Files Modified

**Reads/Writes:**
- TODO.md, BACKLOG.md
- docs/active/*.md
- docs/completed/YYYY-MM/
- docs/strategy/archived/

**Never touches:**
- Source code, README.md, config files

## History Tracking

TaskFlow maintains `.taskflow/history.json` to track operations:

```json
{
  "last_run": {
    "analyze": "2025-11-20T01:30:00Z",
    "compact": "2025-11-20T01:35:00Z",
    "sync": "2025-11-18T14:20:00Z",
    "capture": null,
    "validate": "2025-11-20T01:36:00Z"
  },
  "stats": {
    "tokens_saved": 3300,
    "items_archived": 2,
    "last_backlog_size": 21800
  }
}
```

**Recommendations logic:**
- `compact`: OVERDUE if BACKLOG > 10K AND last_run > 7 days ago
- `analyze`: ⚠️ if > 7 days, ❌ if > 14 days
- `validate`: ⚠️ if compact/archive run but not validated after
- `capture`: ℹ️ reminder if never used (educate user)

## Example Workflows

```bash
# Startup (automatic status check)
/taskflow
# Shows: "BACKLOG 21.8K ❌ Run compact"

# Weekly maintenance
taskflow analyze && taskflow compact && taskflow validate

# After debugging session
taskflow capture   # Preserve discoveries in BACKLOG

# Start new task
taskflow new CAT-004 "Optimize query performance"

# Finish task
taskflow sync    # Check status
taskflow compact # Archive completed work
```

## Quick Archival Process

**When BACKLOG.md > 10K tokens:**

1. Run `taskflow analyze` → see candidates
2. Run `taskflow compact` → auto-archive ✅ items
3. Verify: BACKLOG.md back under 10K
4. All links still work

**Result:** Context stays clean, history preserved, tokens saved.

---

*Designed for token efficiency. Concise skill, powerful automation.*
