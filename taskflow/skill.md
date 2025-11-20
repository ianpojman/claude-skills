# TaskFlow - Token-Efficient Task Management

**Lightweight task management with smart resume.**

## Core Commands

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
taskflow resume TASK-ID
# Example: taskflow resume UI-007
```
Loads:
- ACTIVE.md task index (~1K)
- docs/active/TASK-ID.md details (~3K)
- Total: ~4K tokens vs 10K for old verbose format

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

- taskflow skill: 0.5K
- Status command: 0.05K
- Resume command: 4K (index + details)
- Manual file reads: 1-3K each

**Total per session: 5-6K** (was 53K)
