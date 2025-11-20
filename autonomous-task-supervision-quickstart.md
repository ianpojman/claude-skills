# Autonomous Task Resilience - Quick Reference

## TL;DR
Save task state to `~/.claude/tasks/active/` → Claude survives compaction → Type "resume" to continue

## Setup (Once)
```bash
mkdir -p ~/.claude/tasks/{active,completed,checkpoints}
```

## Workflow

### 1. Start Autonomous Task
User: *"Monitor these EMR jobs overnight"*

Claude creates state file:
```bash
TASK_ID="task_$(date +%Y%m%d_%H%M%S)"
TASK_FILE=~/.claude/tasks/active/${TASK_ID}.json

cat > "$TASK_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "description": "Monitor EMR jobs overnight",
  "total_stages": 3,
  "current_stage": 1,
  "stages": [
    {"id": 1, "name": "Launch", "status": "in_progress"},
    {"id": 2, "name": "Monitor", "status": "pending"},
    {"id": 3, "name": "Report", "status": "pending"}
  ],
  "next_action": {
    "description": "Start monitoring loop",
    "command": "./monitor.sh"
  }
}
EOF

echo "📋 Task: $TASK_FILE"
# Do work...
```

### 2. Update After Each Stage
```bash
# Mark stage 1 complete
jq '.stages[0].status = "completed" | .current_stage = 2' \
  "$TASK_FILE" > "${TASK_FILE}.tmp" && mv "${TASK_FILE}.tmp" "$TASK_FILE"

# Save next action
jq '.next_action = {description: "Continue iteration 5", command: "./monitor.sh --iter 5"}' \
  "$TASK_FILE" > "${TASK_FILE}.tmp" && mv "${TASK_FILE}.tmp" "$TASK_FILE"
```

### 3. After Compaction - Recovery
**Terminal:**
```bash
# Check what was running
ls ~/.claude/tasks/active/*.json

# See task details
cat ~/.claude/tasks/active/task_*.json | jq .
```

**In Claude:**
User: *"resume"*

Claude reads and recovers:
```bash
TASK_FILE=$(ls -t ~/.claude/tasks/active/*.json | head -1)

echo "🔄 RECOVERING TASK"
jq -r '"📋 " + .description + "\n⏱  Stage " + (.current_stage|tostring) + "/" + (.total_stages|tostring) + "\n▶️  Next: " + .next_action.description' "$TASK_FILE"

# Execute next action
eval "$(jq -r '.next_action.command' "$TASK_FILE")"
```

### 4. Complete Task
```bash
mv "$TASK_FILE" ~/.claude/tasks/completed/
echo "✅ Task complete"
```

## Helper Commands

Create `~/bin/task-status`:
```bash
#!/bin/bash
for f in ~/.claude/tasks/active/*.json; do
  [ -e "$f" ] || { echo "No active tasks"; exit; }
  jq -r '"📋 " + .description + "\n   Stage: " + (.current_stage|tostring) + "/" + (.total_stages|tostring) + "\n   Next: " + .next_action.description' "$f"
done
```

Create `~/bin/task-resume`:
```bash
#!/bin/bash
LATEST=$(ls -t ~/.claude/tasks/active/*.json 2>/dev/null | head -1)
[ -z "$LATEST" ] && echo "No active tasks" && exit 1
cat "$LATEST" | jq .
echo ""
echo "💡 Tell Claude: 'resume this task'"
```

Make executable:
```bash
chmod +x ~/bin/task-{status,resume}
```

## Usage Pattern

```
User starts task
    ↓
Claude creates ~/.claude/tasks/active/task_*.json
    ↓
Claude works autonomously, updating state after each stage
    ↓
[COMPACTION HAPPENS]
    ↓
User runs: task-status (or task-resume)
    ↓
User says: "resume"
    ↓
Claude reads state file, continues from where it left off
    ↓
Task completes, moves to ~/.claude/tasks/completed/
```

## Key Principles

1. **Always create state file** for multi-stage tasks
2. **Update after every stage** completion
3. **Save next_action** before transitioning
4. **Check for tasks on session start**
5. **Type "resume" to recover** after compaction

## Example State File
```json
{
  "task_id": "task_20251119_140530",
  "description": "Monitor 5 EMR jobs overnight",
  "total_stages": 3,
  "current_stage": 2,
  "current_iteration": 5,
  "max_iterations": 16,
  "status": "in_progress",
  "stages": [
    {"id": 1, "name": "Launch jobs", "status": "completed"},
    {"id": 2, "name": "Monitor jobs", "status": "in_progress"},
    {"id": 3, "name": "Final report", "status": "pending"}
  ],
  "context": {
    "cluster_ids": ["j-ABC123", "j-DEF456"],
    "failed_jobs": []
  },
  "next_action": {
    "description": "Continue monitoring iteration 6/16",
    "command": "./monitor-emr-jobs.sh --iteration 6"
  },
  "recovery_instructions": "Check job status. If failed, review logs. Continue from iteration 6."
}
```

---

**Bottom line**: Filesystem state = Session resilience. Always persist, always recover.
