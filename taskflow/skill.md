---
name: taskflow
description: Token-efficient task and documentation management. Manages TODO.md, BACKLOG.md archival, validates links, syncs status, and keeps token usage under budget across the three-tier system. Shows startup reminders with last-run tracking and recommendations.
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

```bash
taskflow analyze    # Token usage + archival candidates
                    # Script: ./scripts/taskflow-analyze.sh

taskflow compact    # Archive completed → save tokens
                    # Manual process (guided by skill)

taskflow sync       # Sync TODO ↔ BACKLOG status
                    # Manual check (guided by skill)

taskflow capture    # Create/update items from conversation context
                    # AI-powered (analyzes conversation)

taskflow new        # Create task (TODO + BACKLOG)
                    # Manual process (guided by skill)

taskflow validate   # Check all cross-references
                    # Script: ./scripts/taskflow-validate.sh
```

**Scripts available:**
- ✅ `./scripts/taskflow-analyze.sh` - Works now!
- ✅ `./scripts/taskflow-validate.sh` - Works now!
- Others are AI-guided manual processes

## System Structure

```
TODO.md (2K limit)        → Links to BACKLOG items
BACKLOG.md (10K limit)    → Active/planned work
docs/active/ (5K each)    → Current sprint details
docs/completed/YYYY-MM/   → Archived (not loaded)
docs/strategy/archived/   → Old backlog items
```

## Operations

### `taskflow analyze`
- Count tokens in all docs
- Find files exceeding budgets
- List archival candidates (✅ completed items)
- Show broken links and orphans

**Output:**
```
TODO.md: 1.8K ✅ | BACKLOG.md: 31K ❌ (21K over)
Archive candidates: VER-001 Phase 1 (8K), CAT-003 (4K)
```

### `taskflow compact`
- Move completed items → archives
- Update cross-references
- Regenerate INDEX.md files
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

### `taskflow handoff` (NEW)

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
- Existing docs/strategy/README.md process
- Three-tier system (TODO → active → completed)
- Git workflow (no temp files)

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
