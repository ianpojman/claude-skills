# TaskFlow - Task-Specific Persistent Memory

**Persistent storage for task context across sessions.** Remembers decisions, gotchas, progress, and next steps so you can resume any task without re-discovering everything.

Use slash commands (`/tfs`, `/tfl`, `/tfr`) instead of invoking this skill directly. Type `/tfhelp` for complete reference.

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

## Core Commands

### Quick Status (~50 tokens)
```bash
~/.claude/skills/scripts/taskflow-status-minimal.sh
```
Shows: task counts, branch, token usage

### Resume Task (loads task context on-demand)
```bash
taskflow resume ISSUE-ID
# Example: taskflow resume UI-007, BUG-017, PERF-003
```
Loads:
- ACTIVE.md task index (~1K)
- docs/active/ISSUE-ID.md details (~3K)
- Total: ~4K tokens vs 10K for old verbose format

**IMPORTANT**: When discussing tasks, always reference the filename:
- "See docs/active/UI-007.md for details"
- "PARQ-003.md has the schema fix steps"

### Capture Session Notes
```bash
taskflow capture "summary text"
```
Adds timestamped note with discoveries, fixes, next steps

### Compact ACTIVE.md (archive old session notes)
```bash
~/.claude/skills/scripts/taskflow-compact-active.sh
```
Archives session notes older than 3 days to `docs/session-notes/YYYY-MM-DD.md`

### List All Tasks
```bash
cat ACTIVE.md  # Quick overview (~1K)
```

## How It Works

**Session startup**: Only ACTIVE.md (1K) + BACKLOG.md (1K) = 2K tokens
**When resuming work**: Add task details (3K) = 5K total

## Token Budget

- Status command: 0.05K
- Resume command: 4K (index + details)
- Manual file reads: 1-3K each
- **Total per session: 5-6K**

## Quick Tips

- `/tfstart TASK-ID` — Start working on a task (creates task file if needed)
- `/tfcap` — Capture what you learned this session
- `/tfhandoff` — Save full session context for next time
- `/tfs` (status), `/tfl` (list), `/tfr` (resume), `/tfhelp` (all commands)
