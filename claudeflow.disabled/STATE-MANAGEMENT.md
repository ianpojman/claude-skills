# ClaudeFlow + TaskFlow: Hybrid State Management

**Design Philosophy**: ClaudeFlow manages detailed iteration state, TaskFlow captures high-level milestones.

## Two-Tier State System

### Tier 1: ClaudeFlow State (Detailed, Machine-Readable)

**Purpose**: Enable supervisor decision-making and iteration-by-iteration continuity

**Files**:
- `~/.claude/tasks/active/<task-id>.json` - Current state
- `~/.claude/tasks/checkpoints/<task-id>_context.md` - Iteration history

**Contains**:
- Current iteration number
- Current stage number
- Next action to take
- Validation results
- Stage completion status
- Timestamps

**Updated**: Every iteration (by Claude)

**Read by**: Supervisor script (for control flow) + Claude (for context)

**Example**:
```json
{
  "task_id": "refactor_auth",
  "current_iteration": 7,
  "current_stage": 2,
  "total_stages": 4,
  "stages": [
    {"id": 1, "name": "Extract interfaces", "status": "completed"},
    {"id": 2, "name": "Update implementations", "status": "in_progress"},
    {"id": 3, "name": "Update tests", "status": "pending"},
    {"id": 4, "name": "Verify changes", "status": "pending"}
  ],
  "next_action": "Fix circular dependency in OAuthProvider",
  "validation_result": "failed",
  "taskflow_issue": "REF-001"
}
```

**Context file**:
```markdown
## Iteration 6 - Update LocalAuth
Actions: Implemented IAuthProvider interface
Issues: None
Next: Update OAuthProvider

## Iteration 7 - OAuthProvider (Attempt 1)
Actions: Started implementation
Issues: Circular dependency with SessionStore
Next: Extract ISessionStore first
```

### Tier 2: TaskFlow State (High-Level, Human-Readable)

**Purpose**: Document major milestones and integrate with broader project tracking

**Files**:
- `ACTIVE.md` - Current work
- `BACKLOG.md` - Context for linked issues
- `docs/active/<issue-id>.md` - Detailed documentation

**Contains**:
- Stage completion summaries
- Major discoveries/blockers
- Final results
- Links to ClaudeFlow tasks

**Updated**: At milestones (automatically by Claude)

**Read by**: Humans + Claude (for high-level context)

**Example** (ACTIVE.md):
```markdown
### REF-001: Refactor authentication module
**Status**: ⏳ In progress
**ClaudeFlow**: refactor_auth

**Progress**:
- ✅ Stage 1 complete: Extracted IAuthProvider interface
- ⏳ Stage 2 in progress: Updating implementations
  - Discovery: Circular dependency in OAuthProvider/SessionStore
  - Fix in progress: Extracting ISessionStore interface
- ⏸️ Stage 3 pending: Update tests
- ⏸️ Stage 4 pending: Verify no breaking changes
```

## Automatic Syncing

### When ClaudeFlow Syncs to TaskFlow

**1. Stage Completion**
```bash
# Claude completes stage 1
# Claude updates ClaudeFlow JSON: stage 1 → "completed"
# Claude syncs to TaskFlow:
taskflow capture "refactor_auth: Stage 1 complete - Extracted IAuthProvider interface"
```

**2. Major Discovery/Blocker**
```bash
# Claude discovers circular dependency
# Claude logs in context.md
# Claude syncs to TaskFlow:
taskflow capture "refactor_auth: Discovery - circular dependency in OAuthProvider, extracting ISessionStore"
```

**3. Task Completion**
```bash
# Supervisor detects status = "completed"
# Supervisor syncs to TaskFlow:
taskflow capture "refactor_auth COMPLETE: All 4 stages done - auth module refactored to interface pattern"
```

**4. Validation Failures** (optional)
```bash
# If validation fails critically
# Claude can sync:
taskflow capture "refactor_auth: Validation failed - 12 type errors, fixing batch 1"
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Iteration Loop (Supervisor Script)                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │ Read ClaudeFlow State │
                │ - task.json           │
                │ - context.md          │
                └───────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │ Invoke Claude         │
                └───────────────────────┘
                            │
          ┌─────────────────┴─────────────────┐
          ▼                                   ▼
┌──────────────────────┐          ┌──────────────────────┐
│ Update ClaudeFlow    │          │ Sync to TaskFlow     │
│ State (every iter)   │          │ (milestones only)    │
│                      │          │                      │
│ - task.json          │          │ When:                │
│ - context.md         │          │ - Stage complete     │
│                      │          │ - Major discovery    │
│ Machine-readable     │          │ - Blocker found      │
│ Iteration-level      │          │                      │
└──────────────────────┘          │ Human-readable       │
                                  │ Milestone-level      │
                                  └──────────────────────┘
```

## Benefits of Hybrid Approach

### ✅ Separation of Concerns

**ClaudeFlow**:
- Fast, machine-readable state
- Iteration-by-iteration tracking
- Supervisor control flow
- Detailed debugging history

**TaskFlow**:
- Human-readable summaries
- Project-level context
- Cross-task relationships
- Long-term documentation

### ✅ Best of Both Worlds

- **Granular when needed**: See every iteration in ClaudeFlow
- **Summary when needed**: See milestones in TaskFlow
- **Independent operation**: ClaudeFlow works without TaskFlow
- **Enhanced with integration**: Better with TaskFlow linked

### ✅ Recovery & Context

**If Claude crashes mid-iteration**:
- Supervisor reads ClaudeFlow state
- Knows exactly where to resume
- Context.md has full history

**If starting new session weeks later**:
- Read TaskFlow BACKLOG.md for high-level context
- Read ClaudeFlow context.md for detailed history
- Full picture of what happened

### ✅ Token Efficiency

**Without hybrid**:
- Would need to load all ClaudeFlow iterations every time
- Context window fills with iteration details

**With hybrid**:
- TaskFlow has compressed summaries
- ClaudeFlow has detailed state when needed
- Load appropriate level of detail

## Example: Complete Flow

### Setup
```bash
# 1. Create TaskFlow issue
taskflow new REF-001 "Refactor auth module to use interfaces"

# 2. Create ClaudeFlow task
claudeflow create refactor_auth "REF-001: Refactor auth"
# During setup, links to REF-001

# 3. Start execution
claudeflow start refactor_auth 20
```

### Execution (Iteration 1-5: Stage 1)

**ClaudeFlow state updates**:
```
Iteration 1: Analyze auth module
Iteration 2: Design IAuthProvider interface
Iteration 3: Create interface file
Iteration 4: Add method signatures
Iteration 5: Stage 1 complete
```

**TaskFlow sync** (once at stage completion):
```
REF-001: Stage 1 complete - Extracted IAuthProvider interface with
login(), logout(), refreshToken() methods
```

### Execution (Iteration 6-10: Stage 2)

**ClaudeFlow state updates**:
```
Iteration 6: Update LocalAuth
Iteration 7: Update OAuthProvider - found circular dep
Iteration 8: Extract ISessionStore
Iteration 9: Fix circular dependency
Iteration 10: Stage 2 complete
```

**TaskFlow syncs**:
```
# Discovery sync
REF-001: Discovery - circular dependency between OAuthProvider and SessionStore,
extracting ISessionStore interface

# Stage completion sync
REF-001: Stage 2 complete - Both implementations updated to use interfaces
```

### Completion

**ClaudeFlow**: Task moved to completed/
**TaskFlow sync**:
```
REF-001 COMPLETE: Auth module refactored to interface pattern.
Stages: ✅ Extract interfaces, ✅ Update implementations, ✅ Update tests,
✅ Verify changes. All tests passing.
```

## Reading State

### For Detailed Debugging

```bash
# View iteration-by-iteration
claudeflow context refactor_auth

# See exact state at any point
cat ~/.claude/tasks/active/refactor_auth.json | jq '.'
```

### For High-Level Overview

```bash
# View in TaskFlow
cat ACTIVE.md | grep -A 10 "REF-001"

# See milestones
cat BACKLOG.md | grep -A 20 "REF-001"
```

### For Resume

**New Claude session**:
1. Read ACTIVE.md → See REF-001 in progress
2. See ClaudeFlow task linked
3. Read BACKLOG.md → Get high-level context
4. Read context.md → Get detailed iteration history
5. Read task.json → Get current state
6. Resume work with full context

## Configuration

### Link ClaudeFlow to TaskFlow

**During task creation**:
```bash
claudeflow create my_task "Task description"
# Prompt: "Link to TaskFlow issue: REF-001"
```

**After creation**:
```bash
# Edit task JSON
jq '.taskflow_issue = "REF-001"' ~/.claude/tasks/active/my_task.json > tmp
mv tmp ~/.claude/tasks/active/my_task.json
```

### Control Sync Frequency

**Current defaults**:
- Stage completion: Always sync
- Major discoveries: Claude decides (mentioned in context)
- Validation failures: Only if critical
- Task completion: Always sync

**Custom** (edit prompt in claudeflow script):
```bash
# Sync every 5 iterations
if [ $((i % 5)) -eq 0 ]; then
  taskflow capture "..."
fi

# Sync only on errors
if [ validation failed ]; then
  taskflow capture "..."
fi
```

## Best Practices

### ✅ Do This

- **Link issues**: Always set taskflow_issue if using TaskFlow
- **Let auto-sync work**: Don't manually duplicate state
- **Check both sources**: ClaudeFlow for details, TaskFlow for summaries
- **Use TaskFlow for planning**: Create issue → link to ClaudeFlow
- **Use ClaudeFlow for execution**: Let it manage iterations

### ❌ Avoid This

- **Manual duplication**: Don't copy iteration details to TaskFlow
- **Mixing state**: Don't edit both files for same info
- **Over-syncing**: Don't sync every iteration to TaskFlow
- **Under-syncing**: Don't skip stage completions

## Comparison Table

| Aspect | ClaudeFlow State | TaskFlow State |
|--------|-----------------|----------------|
| **Granularity** | Iteration-level | Milestone-level |
| **Format** | JSON + Markdown | Markdown only |
| **Updated** | Every iteration | Major milestones |
| **Read by** | Supervisor + Claude | Humans + Claude |
| **Purpose** | Execution control | Documentation |
| **Lifetime** | Until task complete | Long-term archive |
| **Tokens** | Context.md can be large | Compressed summaries |
| **Independence** | Self-contained | References ClaudeFlow |

## Summary

**ClaudeFlow state** = Detailed execution log (like flight data recorder)
**TaskFlow state** = High-level project documentation (like captain's log)

**Together** = Complete picture with appropriate detail at each level

---

**Design principle**: Right information, right granularity, right audience, right time.
