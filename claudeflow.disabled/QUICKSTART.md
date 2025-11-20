# ClaudeFlow - Quick Start Guide

**Autonomous task execution in 5 minutes**

## What is ClaudeFlow?

ClaudeFlow runs Claude autonomously in a continuous loop to complete multi-stage tasks. An external supervisor script manages execution while Claude sessions restart as needed. State persists in filesystem.

**Use case**: Any task requiring multiple iterations without manual "continue" prompts.

## Installation

Already installed! Commands available:
- `claudeflow` - Standalone command
- `taskflow flow` - Via TaskFlow integration

## First Task (3 Steps)

### Step 1: Create

```bash
claudeflow create hello_world "My first autonomous task"
```

Interactive prompts:
```
Task description: My first autonomous task
Number of stages (default: 3): 2
Stage 1 name: Create hello.js
Stage 2 name: Test it works
Validation command: node hello.js
Link to TaskFlow issue: [press enter to skip]
```

### Step 2: Start

```bash
claudeflow start hello_world 5
```

ClaudeFlow supervisor now:
1. Invokes Claude with task state
2. Claude creates hello.js
3. Claude updates state file
4. Supervisor runs validation (node hello.js)
5. Claude sees validation result
6. Claude creates tests
7. Claude marks task complete

### Step 3: Review

```bash
# Check status
claudeflow status hello_world

# View iteration history
claudeflow context hello_world

# List all tasks
claudeflow list
```

## Real Example: Test Coverage

```bash
# 1. Create task
claudeflow create add_tests "Improve test coverage"

# Interactive setup:
Stages: 3
Stage 1: Identify untested files
Stage 2: Write unit tests
Stage 3: Verify coverage > 80%
Validation: npm run test:coverage
TaskFlow: COV-001

# 2. Start autonomous execution (max 20 iterations)
claudeflow start add_tests 20

# ClaudeFlow runs:
# Iteration 1: Scans code, finds 12 untested modules
# Iteration 2-8: Writes tests for each module
# Iteration 9: Runs coverage, sees 67%
# Iteration 10-15: Adds more tests
# Iteration 16: Coverage hits 83%
# Iteration 17: Final validation, all pass
# ✅ COMPLETE

# 3. Check results
claudeflow status add_tests
cat ~/.claude/tasks/completed/add_tests.json
```

## With TaskFlow Integration

```bash
# 1. Create TaskFlow issue for high-level tracking
taskflow new REF-001 "Refactor authentication module"

# 2. Create ClaudeFlow task for execution
claudeflow create refactor_auth "REF-001: Refactor auth"
# When prompted for TaskFlow issue: REF-001

# 3. Run
claudeflow start refactor_auth 15

# Claude automatically:
# - Reads BACKLOG.md for REF-001 context
# - Updates ACTIVE.md with progress
# - Documents findings with 'taskflow capture'

# 4. When complete, finalize in TaskFlow
taskflow capture "REF-001 complete: refactored to interface pattern"
```

## Command Reference

### Create & Start
```bash
# Create new task
claudeflow create <task-id> "<description>"

# Start autonomous execution
claudeflow start <task-id> [max-iterations]

# One-liner (non-interactive creation - future feature)
claudeflow quick <task-id> "<description>" --stages 3 --iterations 10
```

### Monitor
```bash
# List all active tasks
claudeflow list

# Check specific task
claudeflow status <task-id>

# View iteration history (what Claude did each iteration)
claudeflow context <task-id>
```

### Control
```bash
# Mark complete manually
claudeflow complete <task-id>
```

## Via TaskFlow

All commands also work via `taskflow flow`:

```bash
taskflow flow create my_task "Description"
taskflow flow start my_task 10
taskflow flow status my_task
taskflow flow list
```

## How It Works

### The Supervisor Loop

```
┌─────────────────────────────────────┐
│ ClaudeFlow Supervisor (bash)        │
│ External process, survives Claude   │
└─────────────────────────────────────┘
              │
              ▼
    ┌─────────────────┐
    │ Iteration 1     │
    │ - Read state    │
    │ - Invoke Claude │ ──► Claude executes stage 1
    │ - Wait          │ ──► Claude updates state
    │ - Validate      │ ──► Run validation command
    └─────────────────┘
              │
              ▼
    ┌─────────────────┐
    │ Iteration 2     │
    │ - Read state    │ ──► State updated by Claude in iter 1
    │ - Invoke Claude │ ──► Claude sees previous context
    │ - Wait          │ ──► Claude continues work
    │ - Validate      │
    └─────────────────┘
              │
              ▼
         ... repeat until complete ...
```

### State Files

**Task State**: `~/.claude/tasks/active/<task-id>.json`
```json
{
  "current_iteration": 5,
  "current_stage": 2,
  "next_action": "Update OAuthProvider implementation"
}
```

**Context History**: `~/.claude/tasks/checkpoints/<task-id>_context.md`
```markdown
## Iteration 4 - Extract Interfaces
Actions: Created IAuthProvider.ts
Next: Update implementations

## Iteration 5 - Update LocalAuth
Actions: Implemented IAuthProvider
Issues: OAuthProvider has circular dependency
Next: Extract ISessionStore first
```

## Common Patterns

### Pattern 1: Iterative Until Success

```bash
# Task: Fix all linting errors
claudeflow create fix_lint "Fix all ESLint errors"
# Validation: npm run lint
# Iteration pattern:
#   - Run lint, see 50 errors
#   - Fix batch 1 (10 errors)
#   - Validate, see 40 errors
#   - Fix batch 2 (10 errors)
#   - ... repeat until 0 errors
```

### Pattern 2: Multi-Stage Sequential

```bash
# Task: Add new feature
claudeflow create new_feature "Add user preferences feature"
# Stages:
#   1. Create database schema
#   2. Build API endpoints
#   3. Create UI components
#   4. Write tests
# Each stage completes before moving to next
```

### Pattern 3: Systematic Processing

```bash
# Task: Migrate 50 files
claudeflow create migrate "Migrate JS to TS"
# Stages:
#   1. Convert all .js to .ts
#   2. Add type annotations (process 5 files per iteration)
#   3. Fix type errors
# Works through files systematically
```

## Tips

### ✅ Do

- **Start small**: First task with 3-5 iterations to test
- **Clear validation**: Use commands that clearly pass/fail
- **Specific stages**: "Extract interfaces" not "refactor code"
- **Monitor first run**: Watch first few iterations
- **Link TaskFlow**: Connect to issues for context/documentation

### ❌ Don't

- **Vague tasks**: "Make it better" won't work
- **No validation**: Can't verify if stages succeeded
- **Edit during run**: Let supervisor manage state
- **Infinite loops**: Always set max iterations
- **One giant stage**: Break into smaller stages

## Troubleshooting

### Task not progressing

```bash
# View what's happening
claudeflow context my_task

# Common issues:
# - Validation always failing → fix validation or disable it
# - Unclear next_action → edit task JSON to be more specific
# - Missing dependencies → ensure tools are installed
```

### Want to resume with more iterations

```bash
# Task hit max iterations (10) but incomplete
# Just restart with higher limit
claudeflow start my_task 20

# Continues from iteration 11
```

### Need to change task mid-run

```bash
# Edit state file directly
vim ~/.claude/tasks/active/my_task.json

# Update:
# - next_action (what Claude should do next)
# - validation_command
# - current_stage

# Resume
claudeflow start my_task 10
```

## Examples Library

### Example: Documentation Sprint

```bash
claudeflow create doc_sprint "Document all API endpoints"
# Stages:
#   1. List all endpoints
#   2. Generate JSDoc comments
#   3. Create API reference
#   4. Add usage examples

claudeflow start doc_sprint 20
```

### Example: Dependency Upgrade

```bash
claudeflow create upgrade_deps "Upgrade to React 18"
# Stages:
#   1. Update package.json
#   2. Fix breaking changes
#   3. Update tests
#   4. Verify build
# Validation: npm test && npm run build

claudeflow start upgrade_deps 30
```

### Example: Performance Optimization

```bash
claudeflow create perf_opt "Optimize render performance"
# Stages:
#   1. Profile components
#   2. Add React.memo
#   3. Optimize re-renders
#   4. Verify improvement
# Validation: npm run perf-test

claudeflow start perf_opt 15
```

## Next Steps

1. **Try the hello_world example above**
2. **Create a real task** for your current project
3. **Monitor the first run** to see how it works
4. **Read full docs**: `~/.claude/skills/claudeflow/SKILL.md`
5. **Check examples**: `~/.claude/skills/claudeflow/EXAMPLES.md`

## Quick Reference Card

```bash
# CREATION
claudeflow create <id> "<desc>"      # Create new task

# EXECUTION
claudeflow start <id> [iters]        # Run autonomously
claudeflow start <id> 10             # Max 10 iterations
claudeflow start <id> 50             # Max 50 iterations

# MONITORING
claudeflow list                      # All tasks
claudeflow status <id>               # Check progress
claudeflow context <id>              # View history

# CONTROL
claudeflow complete <id>             # Mark done

# VIA TASKFLOW
taskflow flow <command> <args>       # Same commands
```

---

**ClaudeFlow**: Set it and forget it. Claude runs autonomously until complete.
