# Continuous Local Execution with TaskFlow Integration

**Purpose**: Run Claude autonomously on multi-stage tasks using filesystem state instead of git PRs, integrated with TaskFlow documentation.

## Concept

Combines three approaches:
- **continuous-claude pattern**: Loop execution with context persistence
- **autonomous-task-supervision**: Filesystem-based state management
- **taskflow**: Task and documentation tracking

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Continuous Execution Loop (bash wrapper)           │
│  ├─ Reads task state from filesystem                │
│  ├─ Invokes Claude with current context             │
│  ├─ Claude updates state + TaskFlow docs            │
│  └─ Repeats until complete or max iterations        │
└─────────────────────────────────────────────────────┘
         │                                      │
         ▼                                      ▼
┌──────────────────────┐            ┌──────────────────────┐
│ State Management     │            │ Task Documentation   │
│ (autonomous-task)    │            │ (taskflow)           │
│                      │            │                      │
│ ~/.claude/tasks/     │            │ ACTIVE.md            │
│   active/            │            │ BACKLOG.md           │
│     task_*.json      │            │ docs/active/         │
│   checkpoints/       │            │ .taskflow/history    │
└──────────────────────┘            └──────────────────────┘
```

## Key Difference from continuous-claude

| Feature | continuous-claude | This Approach |
|---------|------------------|---------------|
| State storage | Git PRs + SHARED_TASK_NOTES.md | ~/.claude/tasks/*.json |
| Progress tracking | PR commits | Filesystem checkpoints |
| Verification | CI checks | Local validation scripts |
| Completion | PR merge | Move to completed/ |
| Documentation | None | TaskFlow ACTIVE/BACKLOG |
| Multi-task | Git worktrees | Multiple .json state files |

## Implementation

### 1. Wrapper Script Pattern

**File**: `~/.claude/scripts/continuous-local.sh`

```bash
#!/bin/bash
# Continuous local execution with filesystem state

TASK_ID="${1:-task_$(date +%Y%m%d_%H%M%S)}"
MAX_ITERATIONS="${2:-10}"
TASK_FILE="$HOME/.claude/tasks/active/${TASK_ID}.json"

# Initialize if new task
if [ ! -f "$TASK_FILE" ]; then
  cat > "$TASK_FILE" <<EOF
{
  "task_id": "$TASK_ID",
  "description": "Task description here",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "max_iterations": $MAX_ITERATIONS,
  "current_iteration": 0,
  "current_stage": 1,
  "total_stages": 3,
  "stages": [
    {"id": 1, "name": "Stage 1", "status": "pending"},
    {"id": 2, "name": "Stage 2", "status": "pending"},
    {"id": 3, "name": "Stage 3", "status": "pending"}
  ],
  "context_file": "$HOME/.claude/tasks/checkpoints/${TASK_ID}_context.md",
  "validation_command": "./validate.sh",
  "next_action": "Initial task execution"
}
EOF

  # Initialize context file (like SHARED_TASK_NOTES.md)
  mkdir -p "$HOME/.claude/tasks/checkpoints"
  cat > "$HOME/.claude/tasks/checkpoints/${TASK_ID}_context.md" <<EOF
# Task Context: $TASK_ID

## Iteration 0 - Initial State
- Task initialized
- Ready to begin

---
EOF
fi

# Main execution loop
for i in $(seq 1 $MAX_ITERATIONS); do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 Iteration $i/$MAX_ITERATIONS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Update iteration count
  jq --arg i "$i" '.current_iteration = ($i|tonumber)' "$TASK_FILE" > "${TASK_FILE}.tmp" && mv "${TASK_FILE}.tmp" "$TASK_FILE"

  # Extract current context
  CONTEXT_FILE=$(jq -r '.context_file' "$TASK_FILE")
  CURRENT_STAGE=$(jq -r '.current_stage' "$TASK_FILE")
  NEXT_ACTION=$(jq -r '.next_action' "$TASK_FILE")

  # Build prompt for Claude
  PROMPT="You are working on a multi-stage autonomous task.

**Task State**: $TASK_FILE
**Current Iteration**: $i/$MAX_ITERATIONS
**Current Stage**: $CURRENT_STAGE
**Next Action**: $NEXT_ACTION

**Previous Context**:
$(cat "$CONTEXT_FILE")

**Instructions**:
1. Read the task state file to understand current progress
2. Execute the next action
3. Update the context file with what you did and what's next
4. Update the task state JSON with new stage/status
5. If validation needed, run the validation command
6. If stage complete, update status and move to next stage
7. If all stages complete, move task to completed/

**Integration with TaskFlow**:
- Use 'taskflow capture' to document discoveries in BACKLOG.md
- Update ACTIVE.md with current task progress
- Link task state to TaskFlow issue IDs when relevant

Proceed autonomously. Do not ask for permission between stages."

  # Invoke Claude (adjust command based on your setup)
  echo "$PROMPT" | claude-code --non-interactive

  # Check if task completed
  STATUS=$(jq -r '.status // "in_progress"' "$TASK_FILE")
  if [ "$STATUS" = "completed" ]; then
    echo "✅ Task completed!"
    mv "$TASK_FILE" "$HOME/.claude/tasks/completed/"
    exit 0
  fi

  # Check if validation passed
  VALIDATION_CMD=$(jq -r '.validation_command // "true"' "$TASK_FILE")
  if ! eval "$VALIDATION_CMD"; then
    echo "❌ Validation failed. Recording in context..."
    echo -e "\n## Iteration $i - Validation Failed\n$(date)\n" >> "$CONTEXT_FILE"
    # Continue to next iteration (Claude will see the failure in context)
  fi

  # Brief pause between iterations
  sleep 2
done

echo "⚠️ Max iterations reached. Task incomplete."
echo "Review state at: $TASK_FILE"
```

### 2. Usage Examples

#### Simple Multi-Stage Task

```bash
# Start autonomous execution
./scripts/continuous-local.sh my_refactor_task 5

# Claude will:
# 1. Read task state
# 2. Execute current stage
# 3. Update context file
# 4. Validate if needed
# 5. Move to next stage
# 6. Repeat until done or max iterations
```

#### With TaskFlow Integration

```bash
# In Claude Code session:

# User: "Autonomously refactor the auth module with 3 stages:
#        1. Extract interfaces, 2. Update implementations, 3. Run tests"

# Claude creates task state:
cat > ~/.claude/tasks/active/task_auth_refactor.json <<EOF
{
  "task_id": "task_auth_refactor",
  "taskflow_issue": "REF-001",
  "description": "Refactor auth module",
  "total_stages": 3,
  "stages": [
    {"id": 1, "name": "Extract interfaces", "status": "pending"},
    {"id": 2, "name": "Update implementations", "status": "pending"},
    {"id": 3, "name": "Run tests", "status": "pending"}
  ]
}
EOF

# Create TaskFlow issue
taskflow new REF-001 "Auth Module Refactor"

# Start continuous execution
./scripts/continuous-local.sh task_auth_refactor 10

# Each iteration:
# - Updates ~/.claude/tasks/active/task_auth_refactor.json
# - Updates ~/.claude/tasks/checkpoints/task_auth_refactor_context.md
# - Captures progress with 'taskflow capture "completed stage X"'
# - Updates ACTIVE.md with current status
```

### 3. Context File Format

**File**: `~/.claude/tasks/checkpoints/{TASK_ID}_context.md`

Similar to continuous-claude's `SHARED_TASK_NOTES.md`:

```markdown
# Task Context: task_auth_refactor

## Iteration 1 - Extract Interfaces
**Date**: 2025-11-20 10:15

**What I did**:
- Created IAuthProvider interface in src/auth/interfaces.ts
- Extracted 3 methods: login(), logout(), refreshToken()
- Found 2 implementations: LocalAuth, OAuthProvider

**Issues encountered**:
- OAuthProvider has dependency on SessionStore
- Need to handle this in stage 2

**Next iteration should**:
- Update LocalAuth to implement IAuthProvider
- Handle SessionStore dependency in OAuthProvider

**Validation**: ✅ TypeScript compiles

---

## Iteration 2 - Update Implementations (Part 1)
**Date**: 2025-11-20 10:17

**What I did**:
- Updated LocalAuth to implement IAuthProvider
- Started OAuthProvider refactor
- Hit issue: SessionStore circular dependency

**Issues encountered**:
- Circular dependency: OAuthProvider -> SessionStore -> IAuthProvider
- Need to extract SessionStore interface first

**Next iteration should**:
- Extract ISessionStore interface
- Update OAuthProvider with both interfaces
- Continue with implementation updates

**Validation**: ❌ Compilation error - circular dep

---

## Iteration 3 - Fix Circular Dependency
...
```

### 4. Integration with TaskFlow

**Pattern**: Link autonomous task state to TaskFlow issues

```bash
# When starting autonomous task, create TaskFlow issue
taskflow new AUTO-001 "Autonomous task: improve test coverage"

# In task state JSON, reference the issue
{
  "task_id": "task_coverage",
  "taskflow_issue": "AUTO-001",
  ...
}

# During execution, Claude updates both:
# 1. Task state file (technical checkpoints)
# 2. TaskFlow ACTIVE.md (high-level progress)

# After completion:
taskflow capture "Completed AUTO-001: improved coverage from 45% to 82%"
```

### 5. Multi-Task Parallel Execution

Unlike continuous-claude's git worktrees, use multiple state files:

```bash
# Start task 1
./scripts/continuous-local.sh refactor_auth 10 &

# Start task 2
./scripts/continuous-local.sh add_tests 10 &

# Start task 3
./scripts/continuous-local.sh update_docs 10 &

# Monitor all
watch -n 5 'ls -1 ~/.claude/tasks/active/ | wc -l'

# View specific task status
jq '.' ~/.claude/tasks/active/refactor_auth.json
```

## Validation Patterns

### Built-in Validation

Tasks can specify validation commands that run after each iteration:

```json
{
  "validation_command": "npm test && npm run lint",
  "validation_required": true,
  "stop_on_validation_failure": false
}
```

### Custom Validators

```bash
# validation.sh - example validator
#!/bin/bash
TASK_FILE=$1

# Check if specific files exist
REQUIRED_FILES=$(jq -r '.required_files[]' "$TASK_FILE")
for f in $REQUIRED_FILES; do
  [ ! -f "$f" ] && echo "Missing: $f" && exit 1
done

# Run tests
npm test || exit 1

# Update task state with validation result
jq '.last_validation = {
  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "status": "passed"
}' "$TASK_FILE" > "${TASK_FILE}.tmp" && mv "${TASK_FILE}.tmp" "$TASK_FILE"
```

## Monitoring and Debugging

### View Active Tasks

```bash
# List all active autonomous tasks
for f in ~/.claude/tasks/active/*.json; do
  echo "$(basename $f):"
  jq -r '"  Stage: \(.current_stage)/\(.total_stages) | Iteration: \(.current_iteration)/\(.max_iterations)"' "$f"
done
```

### Resume After Interruption

```bash
# Task state survives interruption
# Simply restart the continuous-local.sh script

./scripts/continuous-local.sh existing_task_id 10

# Claude reads current state from JSON
# Reads previous context from checkpoint file
# Continues from where it left off
```

### View Progress

```bash
# Watch context file in real-time
tail -f ~/.claude/tasks/checkpoints/task_*.md

# View task state changes
watch -n 2 'jq "." ~/.claude/tasks/active/my_task.json'
```

## Cost Management

Add budget tracking to task state:

```json
{
  "budget": {
    "max_cost_usd": 5.00,
    "current_cost_usd": 1.23,
    "stop_on_budget_exceeded": true
  }
}
```

Track in wrapper script:

```bash
# After each iteration
CURRENT_COST=$(calculate_cost_from_tokens)  # implement based on your tracking
jq --arg cost "$CURRENT_COST" '.budget.current_cost_usd = ($cost|tonumber)' "$TASK_FILE" > "${TASK_FILE}.tmp"

# Check budget
EXCEEDED=$(jq -r 'if .budget.current_cost_usd > .budget.max_cost_usd then "true" else "false" end' "$TASK_FILE")
[ "$EXCEEDED" = "true" ] && echo "💰 Budget exceeded" && exit 1
```

## Comparison Table

| Capability | continuous-claude | This Approach |
|------------|------------------|---------------|
| **State persistence** | Git commits | JSON files |
| **Context continuity** | SHARED_TASK_NOTES.md | Checkpoint .md files |
| **Progress tracking** | PR status | Task state JSON |
| **Verification** | CI checks | Local validators |
| **Documentation** | ❌ None | ✅ TaskFlow integration |
| **Parallel tasks** | Git worktrees | Multiple state files |
| **Interruption recovery** | ✅ Via git | ✅ Via filesystem |
| **Cost tracking** | Run limits | Budget in state |
| **Human oversight** | PR review | TaskFlow ACTIVE.md |

## Benefits

1. **No git required**: Works on non-git projects or local experiments
2. **Filesystem-based**: Simple, portable state management
3. **TaskFlow integration**: Automatic documentation in BACKLOG.md
4. **Survives crashes**: State persists across interruptions
5. **Parallel execution**: Multiple independent tasks
6. **Flexible validation**: Custom validators per task
7. **Cost control**: Budget tracking built-in

## Example: Complete Workflow

```bash
# 1. Create TaskFlow issue
taskflow new COV-001 "Improve test coverage to 80%"

# 2. Initialize autonomous task
cat > ~/.claude/tasks/active/coverage_improvement.json <<EOF
{
  "task_id": "coverage_improvement",
  "taskflow_issue": "COV-001",
  "description": "Incrementally improve test coverage",
  "max_iterations": 20,
  "total_stages": 5,
  "stages": [
    {"id": 1, "name": "Identify untested modules", "status": "pending"},
    {"id": 2, "name": "Write unit tests", "status": "pending"},
    {"id": 3, "name": "Write integration tests", "status": "pending"},
    {"id": 4, "name": "Run coverage report", "status": "pending"},
    {"id": 5, "name": "Verify 80% threshold", "status": "pending"}
  ],
  "validation_command": "npm run test:coverage",
  "budget": {"max_cost_usd": 3.00}
}
EOF

# 3. Start autonomous execution
./scripts/continuous-local.sh coverage_improvement 20

# Claude now runs autonomously:
# - Iteration 1: Scans codebase, identifies 12 untested files
# - Iteration 2-8: Writes tests for each module
# - Iteration 9: Runs coverage, sees 65%
# - Iteration 10-15: Adds integration tests
# - Iteration 16: Coverage reaches 81%
# - Iteration 17: Validates all tests pass
# - DONE: Moves task to completed/

# 4. Review results
cat ~/.claude/tasks/completed/coverage_improvement.json
taskflow capture "COV-001 complete: coverage improved from 42% to 81%"
```

## Tips

- **Start small**: Test with 3-5 iterations first
- **Good validation**: Clear pass/fail criteria per stage
- **Context updates**: Each iteration should update the checkpoint file
- **TaskFlow sync**: Use `taskflow capture` after major milestones
- **Monitor logs**: Watch context files to see Claude's reasoning
- **Budget wisely**: Set cost limits for expensive tasks

---

**See also**:
- `autonomous-task-supervision/SKILL.md` - Core state management patterns
- `taskflow/skill.md` - Task documentation system
- https://github.com/AnandChowdhary/continuous-claude - Original inspiration
