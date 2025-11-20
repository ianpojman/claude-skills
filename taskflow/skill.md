# TaskFlow Minimal - Token-Efficient Task Management

**Ultra-lightweight task management. No fancy formatting.**

## Commands

```bash
# Status (3 lines, ~50 tokens)
~/.claude/scripts/taskflow-status-minimal.sh

# View active tasks (read ACTIVE.md directly)
cat ACTIVE.md

# View specific category
cat docs/backlog/emr-infrastructure.md
```

## DO NOT

- Run taskflow-list.sh (15K tokens)
- Run taskflow-resume.sh (10K tokens)  
- Use ASCII box formatting

## Instead

Just read the markdown files directly:
- ACTIVE.md (3K tokens)
- BACKLOG.md (1K tokens)
- docs/backlog/*.md (when needed)
