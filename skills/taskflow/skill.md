# TaskFlow - Token-Efficient Task Management

**Jira-style task tracking with test plan enforcement.**

⚠️ **IMPORTANT**: Use slash commands (`/tfs`, `/tfl`, `/tfr`) instead of invoking this skill directly. Type `/tfhelp` for complete reference.

**Key feature**: Tasks require Acceptance Criteria + Test Plan before closure.

## Using the TaskFlow Agent (Recommended)

For complex operations (analyze, capture, handoff, validate), use the **TaskFlow agent** to avoid polluting main context:

```python
# Via Task tool
Task(
    subagent_type="taskflow",
    description="Analyze token usage",
    prompt="Run taskflow analyze and report ACTIVE/BACKLOG token counts"
)
```

**Agent has full feature set**: analyze, compact, capture, validate, handoff, search, resume
**Zero token cost** in main context (isolated agent context)

## Core Commands (Manual)

### Quick Status (~50 tokens)
```bash
taskflow status
# or
~/.claude/skills/scripts/taskflow-status-minimal.sh
```
Shows: task counts, branch, token usage

### Compact ACTIVE.md (archive old session notes)
```bash
taskflow compact active
# or
~/.claude/skills/scripts/taskflow-compact-active.sh
```
Archives session notes older than 3 days to `docs/session-notes/YYYY-MM-DD.md`
Keeps ACTIVE.md lean (~500-1000 token savings)

### Resume Task (loads task details on-demand)
```bash
taskflow resume ISSUE-ID
# Example: taskflow resume UI-007, BUG-017, PERF-003
```
Loads:
- ACTIVE.md task index (~1K)
- docs/active/ISSUE-ID.md details (~3K)
- Total: ~4K tokens vs 10K for old verbose format

**IMPORTANT**: When discussing tasks, always reference the filename:
- ✅ "See docs/active/UI-007.md for details"
- ✅ "PARQ-003.md has the schema fix steps"
- ❌ "See UI-007 details" (no filename - harder for next agent)

### List All Tasks
```bash
cat ACTIVE.md  # Quick overview (~1K)
```

### Explore Backlog Category
```bash
cat docs/backlog/emr-infrastructure.md  # Load on-demand
```

## How It Works

**Session startup**: Only ACTIVE.md (1K) + BACKLOG.md (1K) = 2K tokens

**When resuming work**: Add task details (3K) = 5K total

**Old system**: Everything loaded upfront = 53K tokens

## Token Budget

- taskflow skill: 0.5K (avoid loading - use slash commands)
- Status command: 0.05K
- Resume command: 4K (index + details)
- Manual file reads: 1-3K each

**Total per session: 5-6K** (was 53K)

---

## Quick Tips

**Task Lifecycle**:
1. `/tfstart TASK-ID` - Creates task with Acceptance Criteria + Test Plan template
2. Work on task, fill in acceptance criteria
3. Before closing: update Test Plan table with actual results
4. Mark complete only when all tests pass

**Commands**: `/tfs` (status), `/tfl` (list), `/tfr` (resume), `/tfhelp` (all commands)
