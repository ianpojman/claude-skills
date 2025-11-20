# Continuous Local Execution - Quick Start

Run Claude autonomously on multi-stage tasks with filesystem state persistence and TaskFlow integration.

## Installation

The tool is installed at: `~/.claude/scripts/continuous-local.sh`

Add to your PATH (optional):
```bash
echo 'export PATH="$HOME/.claude/scripts:$PATH"' >> ~/.bashrc
```

## 5-Minute Quick Start

### 1. Create a Task

```bash
continuous-local.sh create my_first_task "Improve test coverage"
```

Follow the interactive prompts:
- Number of stages: `3`
- Stage 1: `Identify untested files`
- Stage 2: `Write tests`
- Stage 3: `Run coverage report`
- Validation: `npm test`
- TaskFlow issue: `COV-001` (optional)

### 2. Start Autonomous Execution

```bash
continuous-local.sh start my_first_task 10
```

Claude will now:
- ✅ Execute stage 1
- ✅ Update state automatically
- ✅ Move to stage 2
- ✅ Continue until complete or max iterations

### 3. Monitor Progress

```bash
# View all active tasks
continuous-local.sh list

# Check specific task status
continuous-local.sh status my_first_task

# Watch context/history
continuous-local.sh context my_first_task
```

## Example: Real-World Refactoring

```bash
# 1. Create TaskFlow issue first (optional but recommended)
taskflow new REF-001 "Refactor authentication module"

# 2. Create autonomous task
continuous-local.sh create auth_refactor "Refactor auth module to use interfaces"

# Interactive setup:
#   Stages: 4
#   Stage 1: Extract interfaces
#   Stage 2: Update implementations
#   Stage 3: Update tests
#   Stage 4: Verify no breaking changes
#   Validation: npm test && npm run build
#   TaskFlow: REF-001

# 3. Start autonomous execution (10 iterations max)
continuous-local.sh start auth_refactor 10

# Claude now works autonomously:
# Iteration 1: Analyzes auth code, extracts IAuthProvider interface
# Iteration 2: Updates LocalAuth to implement interface
# Iteration 3: Updates OAuthProvider, discovers circular dependency
# Iteration 4: Fixes circular dependency with ISessionStore
# Iteration 5: Completes stage 1, moves to stage 2
# Iteration 6-8: Updates implementations
# Iteration 9: Updates tests
# Iteration 10: Runs validation, all pass, task complete!

# 4. Review results
continuous-local.sh status auth_refactor
continuous-local.sh context auth_refactor

# 5. Document in TaskFlow
taskflow capture "REF-001 complete: auth module now uses interface pattern"
```

## How It Works

### Filesystem State

```
~/.claude/tasks/
  active/
    auth_refactor.json          # Current state
  checkpoints/
    auth_refactor_context.md    # History/context (like SHARED_TASK_NOTES)
  completed/
    old_task.json               # Archived completed tasks
```

### Task State File

```json
{
  "task_id": "auth_refactor",
  "description": "Refactor auth module",
  "taskflow_issue": "REF-001",
  "status": "in_progress",
  "current_iteration": 5,
  "max_iterations": 10,
  "current_stage": 2,
  "total_stages": 4,
  "stages": [
    {"id": 1, "name": "Extract interfaces", "status": "completed"},
    {"id": 2, "name": "Update implementations", "status": "in_progress"},
    {"id": 3, "name": "Update tests", "status": "pending"},
    {"id": 4, "name": "Verify changes", "status": "pending"}
  ],
  "validation_command": "npm test && npm run build",
  "next_action": "Continue updating OAuthProvider implementation"
}
```

### Context File (Continuity Across Iterations)

```markdown
# Task Context: auth_refactor

## Iteration 1 - Extract IAuthProvider Interface
**Date**: 2025-11-20 10:15

**Actions**:
- Created src/auth/interfaces/IAuthProvider.ts
- Defined methods: login(), logout(), refreshToken()
- Found 2 implementations to update

**Next**: Update LocalAuth to implement IAuthProvider

---

## Iteration 2 - Update LocalAuth
**Date**: 2025-11-20 10:17

**Actions**:
- Modified src/auth/LocalAuth.ts
- Implements IAuthProvider interface
- All methods match interface signature

**Issues**: OAuthProvider has dependency on SessionStore

**Next**: Handle SessionStore dependency in OAuthProvider

---

## Iteration 3 - OAuthProvider + Circular Dependency
...
```

## Commands Reference

```bash
# Create new task
continuous-local.sh create <task-id> "<description>"

# Start/resume execution
continuous-local.sh start <task-id> [max-iterations]

# Monitor
continuous-local.sh list                    # All tasks
continuous-local.sh status <task-id>        # Specific task
continuous-local.sh context <task-id>       # View history

# Manual control
continuous-local.sh complete <task-id>      # Mark complete
```

## Integration with TaskFlow

### Pattern 1: Task -> TaskFlow

```bash
# 1. Create autonomous task
continuous-local.sh create optimize_db "Optimize database queries"

# 2. Link to TaskFlow during/after
taskflow new OPT-001 "Database optimization"

# 3. Update task to reference it
jq '.taskflow_issue = "OPT-001"' ~/.claude/tasks/active/optimize_db.json > tmp && mv tmp ~/.claude/tasks/active/optimize_db.json

# 4. Run autonomously
continuous-local.sh start optimize_db 15

# 5. Claude automatically captures progress
# (The prompt tells Claude to use 'taskflow capture' at milestones)
```

### Pattern 2: TaskFlow -> Task

```bash
# 1. Create TaskFlow issue first
taskflow new FIX-042 "Fix memory leak in worker pool"

# 2. Create autonomous task with link
continuous-local.sh create fix_memory_leak "Fix FIX-042 memory leak"
# During setup, enter TaskFlow issue: FIX-042

# 3. Run
continuous-local.sh start fix_memory_leak 10

# Claude sees the link and:
# - Reads BACKLOG.md for context about FIX-042
# - Updates ACTIVE.md with progress
# - Uses 'taskflow capture' to document findings
```

## Common Patterns

### Multi-Task Parallel Execution

```bash
# Start multiple tasks (background)
continuous-local.sh start task1 10 &
continuous-local.sh start task2 10 &
continuous-local.sh start task3 10 &

# Monitor all
watch -n 5 'continuous-local.sh list'
```

### Long-Running Tasks (Overnight)

```bash
# Start with high iteration count
continuous-local.sh start large_refactor 100 > /tmp/refactor.log 2>&1 &

# Check in the morning
continuous-local.sh status large_refactor
tail -f ~/.claude/tasks/checkpoints/large_refactor_context.md
```

### Interrupted Tasks (Resume)

```bash
# Task interrupted at iteration 7/20
# Simply restart:
continuous-local.sh start my_task 20

# Claude reads current state from JSON
# Reads previous context from checkpoint file
# Continues from iteration 8
```

## Tips & Best Practices

### ✅ Do This

- **Start small**: Test with 3-5 iterations first
- **Clear stages**: Each stage should have clear completion criteria
- **Good validation**: Use validation commands that give clear pass/fail
- **Context updates**: Trust Claude to update the context file each iteration
- **Monitor early**: Watch first few iterations to ensure correct behavior
- **Link TaskFlow**: Use TaskFlow for high-level tracking, task state for execution

### ❌ Avoid This

- **Vague stages**: "Do stuff" is not a good stage name
- **No validation**: Without validation, hard to know if stages succeeded
- **Too many stages**: 10+ stages might be better split into multiple tasks
- **Manual intervention**: Don't edit state files during execution
- **Interrupting**: Let Claude finish iterations cleanly

## Troubleshooting

### Task stuck or looping

```bash
# Check context to see what Claude is doing
continuous-local.sh context stuck_task

# Look for repeated patterns indicating confusion
# Common causes:
# - Validation command always failing
# - Unclear next_action instructions
# - Missing dependencies

# Fix: Update task state manually
vim ~/.claude/tasks/active/stuck_task.json
# Update next_action with clearer instructions

# Resume
continuous-local.sh start stuck_task 5
```

### Validation always fails

```bash
# Check validation command
jq -r '.validation_command' ~/.claude/tasks/active/my_task.json

# Test manually
npm test  # or whatever the command is

# Fix validation or disable it temporarily
jq '.validation_command = "true"' ~/.claude/tasks/active/my_task.json > tmp && mv tmp ~/.claude/tasks/active/my_task.json
```

### Want to change number of iterations

```bash
# Just restart with new max
continuous-local.sh start my_task 25

# Overrides max_iterations in state file
```

## Advanced: Custom Prompts

Edit `~/.claude/scripts/continuous-local.sh` to customize the prompt sent to Claude on each iteration. Look for the section:

```bash
local prompt="You are working on a multi-stage autonomous task..."
```

Add custom instructions:
- Project-specific context
- Coding standards
- Testing requirements
- Documentation expectations

## Comparison to continuous-claude

| Feature | continuous-claude | continuous-local |
|---------|------------------|------------------|
| **Execution** | Git-based PRs | Local filesystem |
| **State** | Commits | JSON files |
| **Context** | SHARED_TASK_NOTES.md | checkpoint/*.md |
| **Validation** | CI checks | Local commands |
| **Documentation** | None | TaskFlow integration |
| **Setup** | GitHub token, repo | Just filesystem |
| **Use case** | Open source projects | Local dev, experiments |

## What's Next?

1. **Try the first example** above
2. **Check the context file** after a few iterations
3. **Integrate with TaskFlow** for documentation
4. **Build your own tasks** - automation is powerful!

See full documentation: `~/.claude/skills/autonomous-task-supervision/CONTINUOUS-LOCAL.md`
