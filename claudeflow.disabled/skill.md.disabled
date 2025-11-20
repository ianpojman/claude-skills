---
name: claudeflow
description: Autonomous multi-stage task execution with continuous iteration. External supervisor runs Claude repeatedly with filesystem state persistence and TaskFlow integration. Use when user wants autonomous/overnight execution or continuous iteration until complete.
---

# ClaudeFlow

**Autonomous task execution with continuous iteration and TaskFlow integration**

ClaudeFlow runs Claude autonomously in a persistent loop to complete multi-stage tasks without manual intervention. An external supervisor script manages the execution while Claude sessions can restart/reset as needed.

## What is ClaudeFlow?

**The Problem**: Claude sessions are stateless. You need to manually tell Claude to "continue" after each step, and context resets lose progress.

**The Solution**: ClaudeFlow is an external supervisor (bash script) that:
- ✅ Runs Claude in a continuous loop
- ✅ Persists state to filesystem between iterations
- ✅ Maintains context history across Claude restarts
- ✅ Automatically progresses through stages
- ✅ Integrates with TaskFlow for documentation
- ✅ Survives crashes, compaction, and session resets

## Quick Start

```bash
# Three ways to use ClaudeFlow:

# 1. Standalone command
claudeflow create my_task "Task description"
claudeflow start my_task 10

# 2. Via TaskFlow
taskflow flow create my_task "Task description"
taskflow flow start my_task 10

# 3. Just type "claudeflow" for help
claudeflow
```

## 5-Minute Example

```bash
# Create a task with 3 stages
claudeflow create refactor_auth "Refactor auth module"
# Interactive prompts:
#   Stages: 3
#   Stage 1: Extract interfaces
#   Stage 2: Update implementations
#   Stage 3: Update tests
#   Validation: npm test
#   TaskFlow: REF-001

# Start autonomous execution
claudeflow start refactor_auth 15

# ClaudeFlow supervisor now:
# 1. Invokes Claude with current state
# 2. Claude executes current stage
# 3. Claude updates state file + context
# 4. Supervisor validates if needed
# 5. Repeats until complete or max iterations
# 6. Claude sessions can die/restart - supervisor persists!
```

## Architecture

```
┌─────────────────────────────────────────────┐
│  ClaudeFlow Supervisor (bash)               │
│  Runs continuously, survives Claude resets  │
│                                             │
│  Loop:                                      │
│    1. Read task state from filesystem       │
│    2. Invoke Claude with context            │
│    3. Wait for Claude to complete iteration │
│    4. Run validation if specified           │
│    5. Check if task complete                │
│    6. Repeat                                │
└─────────────────────────────────────────────┘
              │                    │
              ▼                    ▼
    ┌──────────────────┐  ┌──────────────────┐
    │ State Files      │  │ TaskFlow Docs    │
    │                  │  │                  │
    │ ~/.claude/tasks/ │  │ ACTIVE.md        │
    │   active/*.json  │  │ BACKLOG.md       │
    │   checkpoints/*  │  │ docs/active/     │
    └──────────────────┘  └──────────────────┘
```

**Key Insight**: The supervisor script is external to Claude, so:
- Claude sessions can crash/reset → supervisor continues
- Context window full → supervisor restarts with fresh context
- Long-running tasks → supervisor runs overnight
- State persists in filesystem → always recoverable

## Commands

```bash
# Create new task
claudeflow create <task-id> "<description>"

# Start/resume autonomous execution
claudeflow start <task-id> [max-iterations]

# Monitor
claudeflow list                    # All active tasks
claudeflow status <task-id>        # Specific task
claudeflow context <task-id>       # View iteration history

# Control
claudeflow complete <task-id>      # Mark complete & archive
```

## Integration with TaskFlow

ClaudeFlow is designed to work seamlessly with TaskFlow:

### Pattern 1: TaskFlow → ClaudeFlow

```bash
# 1. Create TaskFlow issue for high-level tracking
taskflow new REF-001 "Refactor authentication module"

# 2. Create ClaudeFlow task for autonomous execution
claudeflow create auth_refactor "REF-001: Refactor auth"
# Link to REF-001 during setup

# 3. Run autonomously
claudeflow start auth_refactor 20

# 4. Claude automatically:
#    - Reads BACKLOG.md for REF-001 context
#    - Updates ACTIVE.md with progress
#    - Uses 'taskflow capture' at milestones
#    - Documents findings in BACKLOG.md
```

### Pattern 2: Standalone ClaudeFlow

```bash
# Quick experiments without TaskFlow overhead
claudeflow create quick_fix "Fix bug in parser"
claudeflow start quick_fix 5
```

### Pattern 3: Via TaskFlow Subcommand

```bash
# Use taskflow as the main command
taskflow flow create my_task "Task description"
taskflow flow start my_task 10
taskflow flow status my_task
```

## State Management

### Task State File
`~/.claude/tasks/active/<task-id>.json`

```json
{
  "task_id": "auth_refactor",
  "description": "Refactor auth module",
  "taskflow_issue": "REF-001",
  "status": "in_progress",
  "current_iteration": 7,
  "max_iterations": 20,
  "current_stage": 2,
  "total_stages": 3,
  "stages": [
    {"id": 1, "name": "Extract interfaces", "status": "completed"},
    {"id": 2, "name": "Update implementations", "status": "in_progress"},
    {"id": 3, "name": "Update tests", "status": "pending"}
  ],
  "validation_command": "npm test",
  "next_action": "Continue updating OAuthProvider",
  "created_at": "2025-11-20T10:00:00Z",
  "updated_at": "2025-11-20T10:45:00Z"
}
```

### Context History
`~/.claude/tasks/checkpoints/<task-id>_context.md`

Maintains iteration history (like continuous-claude's SHARED_TASK_NOTES.md):

```markdown
## Iteration 5 - Update LocalAuth
**Date**: 2025-11-20 10:30

**Actions**:
- Modified LocalAuth.ts to implement IAuthProvider
- Updated all method signatures

**Issues**: None

**Next**: Update OAuthProvider

---

## Iteration 6 - OAuthProvider Refactor
**Date**: 2025-11-20 10:35

**Actions**:
- Started OAuthProvider refactor
- Hit circular dependency with SessionStore

**Issues**: Circular dependency detected

**Next**: Extract ISessionStore interface first

---
```

## When to Use ClaudeFlow

### ✅ Perfect For

- **Multi-stage refactoring** - Extract, update, test, verify
- **Incremental improvements** - Add tests until 80% coverage
- **Iterative debugging** - Try fix, test, adjust, repeat
- **Overnight tasks** - Long-running work that doesn't need supervision
- **Systematic migrations** - Update 20 files following same pattern
- **Documentation generation** - Document all API endpoints

### ❌ Not Ideal For

- **Single simple tasks** - Just use Claude directly
- **Highly creative work** - Needs human judgment each step
- **Requires external input** - Waiting for API responses, user input
- **Unpredictable tasks** - Can't define clear stages upfront

## Examples

### Example 1: Test Coverage Improvement

```bash
claudeflow create improve_coverage "Improve test coverage to 80%"
# Stages:
#   1. Identify untested modules
#   2. Write unit tests (iterate until coverage > 80%)
#   3. Run full test suite
#   4. Verify coverage report
# Validation: npm run test:coverage
# Max iterations: 25

claudeflow start improve_coverage 25

# ClaudeFlow runs autonomously:
# Iteration 1-3: Scans codebase, identifies 15 untested files
# Iteration 4-18: Writes tests, checks coverage after each
# Iteration 19: Coverage hits 82%
# Iteration 20: Runs full suite, all pass
# Iteration 21: Generates coverage report
# COMPLETE ✅
```

### Example 2: Systematic Refactoring

```bash
claudeflow create migrate_to_ts "Migrate JS files to TypeScript"
# Stages:
#   1. Convert all .js to .ts
#   2. Add type annotations
#   3. Fix type errors
#   4. Update imports
# Validation: npm run type-check
# Max iterations: 50

claudeflow start migrate_to_ts 50

# Runs overnight, converts 30 files systematically
```

### Example 3: Documentation Sprint

```bash
claudeflow create doc_apis "Document all API endpoints"
# Stages:
#   1. List all endpoints
#   2. Generate OpenAPI specs
#   3. Write usage examples
#   4. Create README
# Validation: npm run docs:validate
# Max iterations: 30

claudeflow start doc_apis 30
```

## Advanced Features

### Parallel Tasks

```bash
# Run multiple ClaudeFlow tasks simultaneously
claudeflow start task1 20 &
claudeflow start task2 15 &
claudeflow start task3 10 &

# Monitor all
watch -n 5 'claudeflow list'
```

### Resume After Interruption

```bash
# Task interrupted? Just restart
claudeflow start my_task 20

# Supervisor reads current state from filesystem
# Continues from where it left off
```

### Custom Validation

```bash
# In task JSON, specify validation
{
  "validation_command": "./scripts/validate.sh",
  "stop_on_validation_failure": false
}

# Validation runs after each iteration
# Results recorded in task state
```

## Comparison

| Feature | Manual Claude | ClaudeFlow | continuous-claude |
|---------|--------------|------------|-------------------|
| **Continuous execution** | ❌ Manual "continue" | ✅ Automatic | ✅ Automatic |
| **State persistence** | ❌ None | ✅ Filesystem | ✅ Git commits |
| **Survives crashes** | ❌ No | ✅ Yes | ✅ Yes |
| **Context continuity** | ❌ Lost on reset | ✅ Checkpoint files | ✅ SHARED_TASK_NOTES |
| **Requires git** | ❌ No | ❌ No | ✅ Yes |
| **Documentation** | ❌ Manual | ✅ TaskFlow | ❌ None |
| **Local experiments** | ✅ Easy | ✅ Easy | ❌ Needs repo |
| **Parallel tasks** | ❌ No | ✅ Yes | ✅ Git worktrees |

## Tips & Best Practices

### ✅ Do This

- **Clear stages**: Each stage should have obvious completion criteria
- **Good validation**: Commands that give clear pass/fail signals
- **Link TaskFlow**: Reference TaskFlow issues for context
- **Start small**: Test with 5-10 iterations first
- **Monitor early**: Watch first few iterations to verify behavior
- **Descriptive next_action**: Help Claude know what to do next

### ❌ Avoid This

- **Vague stages**: "Do stuff" won't work well
- **No validation**: Hard to verify stage completion
- **Too many stages**: 10+ might need splitting
- **Manual edits during run**: Let the supervisor manage state
- **Missing dependencies**: Ensure tools/files exist before starting

## Troubleshooting

### Task seems stuck

```bash
# Check what Claude is doing
claudeflow context my_task

# Look for repeated patterns
# Common causes:
#   - Validation always failing
#   - Unclear next_action
#   - Missing dependencies

# Fix: Update next_action
vim ~/.claude/tasks/active/my_task.json
# Make next_action more specific

# Resume
claudeflow start my_task 5
```

### Validation failing

```bash
# Test validation manually
npm test  # or whatever your validation is

# Temporarily disable to unblock
jq '.validation_command = "true"' ~/.claude/tasks/active/my_task.json > tmp && mv tmp ~/.claude/tasks/active/my_task.json

# Resume
claudeflow start my_task 10
```

## Files & Locations

```
~/.claude/
  scripts/
    claudeflow                    # Main tool
    taskflow-flow.sh             # TaskFlow integration
  tasks/
    active/
      <task-id>.json             # Current state
    checkpoints/
      <task-id>_context.md       # Iteration history
    completed/
      <task-id>.json             # Archived tasks
  skills/
    claudeflow/
      SKILL.md                   # This file
      QUICKSTART.md              # Getting started
      EXAMPLES.md                # Detailed examples
```

## Related

- **TaskFlow**: High-level task/doc management (`taskflow` command)
- **autonomous-task-supervision**: Manual state management patterns
- **continuous-claude**: Git-based continuous execution (inspiration)

## Getting Started

1. **Read the quick start**: `~/.claude/skills/claudeflow/QUICKSTART.md`
2. **Try an example**: `claudeflow create test_task "My first task"`
3. **Run it**: `claudeflow start test_task 5`
4. **Monitor**: `claudeflow status test_task`

---

**ClaudeFlow**: Autonomous execution, powered by filesystem state, integrated with TaskFlow.
