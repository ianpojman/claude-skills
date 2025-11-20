---
name: autonomous-task-supervision
description: Work autonomously on multi-stage tasks with session resilience via filesystem state. Use when user says "autonomous", "don't stop", "overnight", or task has 3+ sequential stages requiring monitoring → action → next stage. Creates checkpointed state in ~/.claude/tasks/active/ to survive compaction and context resets.
---

# Autonomous Task Supervision Skill

**Purpose**: Work autonomously on multi-stage tasks with session resilience via filesystem state.

## Quick Reference

**Setup**: `mkdir -p ~/.claude/tasks/{active,completed,checkpoints}`

**Pattern**: Create state → Update each stage → Type "resume" after compaction → Continue

**Tool**: `continuous-local.sh` - Automated continuous execution wrapper (see QUICKSTART.md)

**Commands**: `task-status`, `task-resume`, `task-complete` (installed in ~/bin/)

## Core Principles

1. **Never stop between stages** - IMMEDIATELY transition to next stage
2. **Always count iterations** - "Stage 3/7" or "Iteration 5/16"
3. **Persist state to filesystem** - Survive compaction
4. **Update state after each stage** - Enable recovery
5. **Check for tasks on session start** - Auto-recover when possible

## State File Pattern

**Create at task start**:
```bash
TASK_ID="task_$(date +%Y%m%d_%H%M%S)"
cat > ~/.claude/tasks/active/${TASK_ID}.json <<EOF
{
  "task_id": "$TASK_ID",
  "description": "Task description",
  "total_stages": 3,
  "current_stage": 1,
  "stages": [
    {"id": 1, "name": "Stage 1", "status": "in_progress"},
    {"id": 2, "name": "Stage 2", "status": "pending"},
    {"id": 3, "name": "Stage 3", "status": "pending"}
  ],
  "next_action": {"description": "Next step", "command": "./script.sh"}
}
EOF
```

**Update after stage**:
```bash
jq '.current_stage = 2 | .stages[0].status = "completed"' $TASK_FILE > ${TASK_FILE}.tmp && mv ${TASK_FILE}.tmp $TASK_FILE
jq '.next_action = {description: "Step 2", command: "./step2.sh"}' $TASK_FILE > ${TASK_FILE}.tmp && mv ${TASK_FILE}.tmp $TASK_FILE
```

**Complete task**:
```bash
mv $TASK_FILE ~/.claude/tasks/completed/
```

## Recovery Pattern

**User says "resume" after compaction**:
```bash
TASK_FILE=$(ls -t ~/.claude/tasks/active/*.json | head -1)
echo "🔄 Recovering: $(jq -r '.description' $TASK_FILE)"
echo "Stage $(jq -r '.current_stage' $TASK_FILE)/$(jq -r '.total_stages' $TASK_FILE)"
echo "Next: $(jq -r '.next_action.description' $TASK_FILE)"
eval "$(jq -r '.next_action.command' $TASK_FILE)"
```

## Monitoring Scripts

**Include state updates**:
```bash
#!/bin/bash
TASK_FILE=$1
MAX=$(jq -r '.max_iterations' $TASK_FILE)

for i in $(seq 1 $MAX); do
  jq --arg i "$i" '.current_iteration = ($i|tonumber)' $TASK_FILE > ${TASK_FILE}.tmp && mv ${TASK_FILE}.tmp $TASK_FILE

  # Do work, check status
  if [ "$STATUS" = "complete" ]; then
    jq '.current_stage += 1' $TASK_FILE > ${TASK_FILE}.tmp && mv ${TASK_FILE}.tmp $TASK_FILE
    eval "$(jq -r '.next_action.command' $TASK_FILE)"  # Auto-trigger next stage
    exit 0
  fi

  sleep 1800
done
```

## Session Start Check

**Always check for incomplete tasks**:
```bash
if ls ~/.claude/tasks/active/*.json >/dev/null 2>&1; then
  for f in ~/.claude/tasks/active/*.json; do
    echo "📋 $(jq -r '.description' $f) - Stage $(jq -r '.current_stage' $f)/$(jq -r '.total_stages' $f)"
  done
  echo "Type 'resume' to continue"
fi
```

## Critical Rules

1. **NEVER** say "Let me know when..." in multi-stage tasks
2. **ALWAYS** create state file for tasks with 3+ stages
3. **UPDATE** state after every stage completion
4. **SAVE** next_action before transitions
5. **IMMEDIATELY** transition to next stage after current completes

## When to Invoke This Skill

Use this skill when:
- User says "autonomous", "don't stop", or "overnight"
- Task has 3+ sequential stages
- Task requires monitoring → action → next stage
- User mentions "iterations" or "until it works"
- Long-running operations that may survive session resets

## Anti-Patterns

❌ Waiting for user between stages
❌ Not tracking iteration/stage number
❌ Creating monitoring script without auto-progression
❌ Not creating state file for multi-stage tasks
❌ Asking "Should I continue?"

## Success Metrics

✅ User never says "continue" or "next step"
✅ State file exists in ~/.claude/tasks/active/
✅ Recovery works after compaction
✅ All stages complete in one session
✅ Monitoring scripts auto-trigger next stage

---

## Continuous Local Execution Tool

**NEW**: Automated wrapper for continuous execution pattern (inspired by continuous-claude).

**Tool**: `~/.claude/scripts/continuous-local.sh`

**Quick Start**:
```bash
# Create task
continuous-local.sh create my_task "Task description"

# Run autonomously
continuous-local.sh start my_task 10

# Monitor
continuous-local.sh status my_task
continuous-local.sh context my_task
```

**Features**:
- ✅ Automated iteration loop (no manual "continue" needed)
- ✅ Filesystem state persistence (survives crashes)
- ✅ Context continuity between iterations
- ✅ TaskFlow integration
- ✅ Validation commands
- ✅ Parallel task execution

**Documentation**:
- Quick start: `QUICKSTART.md`
- Full guide: `CONTINUOUS-LOCAL.md`

**Use when**: You want fully automated continuous execution similar to continuous-claude but using local filesystem instead of git PRs.

---

**See Also**:
- `QUICKSTART.md` - Getting started with continuous-local tool
- `CONTINUOUS-LOCAL.md` - Complete documentation for continuous execution pattern
