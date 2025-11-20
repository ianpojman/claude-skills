# ClaudeFlow

**Autonomous multi-stage task execution with filesystem state persistence**

## What is ClaudeFlow?

ClaudeFlow runs Claude autonomously in a continuous loop to complete complex tasks without manual intervention. Inspired by [continuous-claude](https://github.com/AnandChowdhary/continuous-claude) but uses local filesystem instead of git PRs, with full TaskFlow integration.

## Key Features

- ✅ **Autonomous execution**: No manual "continue" needed
- ✅ **Filesystem state**: Survives crashes and session resets
- ✅ **External supervisor**: Bash script persists while Claude restarts
- ✅ **Context continuity**: Iteration history like continuous-claude's SHARED_TASK_NOTES
- ✅ **TaskFlow integration**: Auto-documents in BACKLOG.md
- ✅ **Parallel tasks**: Run multiple tasks simultaneously
- ✅ **Validation**: Built-in command execution and verification

## Installation

Already installed! Located at: `~/.claude/scripts/claudeflow`

### Add to PATH (recommended)

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/.claude/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Or for zsh
echo 'export PATH="$HOME/.claude/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Now you can use:
claudeflow <command>
```

### Or use full path

```bash
~/.claude/scripts/claudeflow <command>
```

### Or via TaskFlow

```bash
taskflow flow <command>
```

## Quick Start

```bash
# 1. Create a task
claudeflow create my_task "Improve test coverage"
# Follow interactive prompts

# 2. Run autonomously
claudeflow start my_task 10

# 3. Monitor
claudeflow status my_task
claudeflow context my_task
```

## Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Get started in 5 minutes
- **[SKILL.md](./SKILL.md)** - Complete documentation
- **[EXAMPLES.md](./EXAMPLES.md)** - Real-world examples

## Example Use Cases

- ✅ Improve test coverage to 80%
- ✅ Refactor module to use interfaces
- ✅ Migrate 30 JS files to TypeScript
- ✅ Fix all ESLint errors
- ✅ Document all API endpoints
- ✅ Upgrade React 17 → 18
- ✅ Optimize component performance
- ✅ Fix npm audit vulnerabilities

## How It Works

### The Supervisor Pattern

```
External Supervisor (bash)
  │
  ├─► Iteration 1: Invoke Claude → Execute stage 1 → Update state
  │
  ├─► Iteration 2: Invoke Claude → Execute stage 2 → Update state
  │
  ├─► Iteration 3: Invoke Claude → Execute stage 3 → Validate
  │
  └─► ... repeat until complete
```

The supervisor script runs externally, so:
- Claude sessions can crash → supervisor continues
- Context resets → supervisor provides state
- Long-running tasks → supervisor persists overnight

### State Persistence

**Task State**: `~/.claude/tasks/active/<task-id>.json`
```json
{
  "current_iteration": 5,
  "current_stage": 2,
  "next_action": "Continue implementation"
}
```

**Context History**: `~/.claude/tasks/checkpoints/<task-id>_context.md`
```markdown
## Iteration 4
Actions: Extracted interfaces
Next: Update implementations

## Iteration 5
Actions: Updated LocalAuth
Issues: Found circular dependency
Next: Fix circular dep
```

## Integration with TaskFlow

```bash
# Create TaskFlow issue for high-level tracking
taskflow new REF-001 "Refactor auth module"

# Create ClaudeFlow task for execution
claudeflow create refactor "REF-001: Refactor auth"

# Run autonomously
claudeflow start refactor 20

# Claude automatically:
# - Reads BACKLOG.md for context
# - Updates ACTIVE.md with progress
# - Documents findings via 'taskflow capture'
```

## Commands

```bash
# Create
claudeflow create <task-id> "<description>"

# Execute
claudeflow start <task-id> [max-iterations]

# Monitor
claudeflow list                    # All tasks
claudeflow status <task-id>        # Specific task
claudeflow context <task-id>       # Iteration history

# Control
claudeflow complete <task-id>      # Mark complete
```

## Comparison

| Feature | Manual | ClaudeFlow | continuous-claude |
|---------|--------|-----------|-------------------|
| Autonomous | ❌ | ✅ | ✅ |
| Local/No git | ✅ | ✅ | ❌ |
| State persistence | ❌ | ✅ Filesystem | ✅ Git |
| Documentation | ❌ | ✅ TaskFlow | ❌ |
| Survives crashes | ❌ | ✅ | ✅ |

## Architecture

```
ClaudeFlow Ecosystem
├── claudeflow              # Main tool
├── taskflow flow          # TaskFlow integration
└── Skills
    ├── claudeflow/        # This skill
    │   ├── SKILL.md
    │   ├── QUICKSTART.md
    │   └── EXAMPLES.md
    └── taskflow/          # Task management
        └── skill.md
```

## Getting Started

1. **Read**: [QUICKSTART.md](./QUICKSTART.md)
2. **Try**: Create your first task
3. **Learn**: Check [EXAMPLES.md](./EXAMPLES.md)
4. **Integrate**: Link with TaskFlow issues

## Tips

✅ **Do**: Start with 3-5 iterations to test
✅ **Do**: Use clear, specific stage names
✅ **Do**: Link to TaskFlow issues for context
✅ **Do**: Monitor first few iterations

❌ **Don't**: Use vague task descriptions
❌ **Don't**: Skip validation commands
❌ **Don't**: Edit state files during execution

## Support

- Issues: Create in your TaskFlow BACKLOG.md
- Examples: See EXAMPLES.md
- Full docs: See SKILL.md

---

**ClaudeFlow**: Set it, forget it, get results.

**Powered by**: Filesystem state + External supervision + TaskFlow integration
