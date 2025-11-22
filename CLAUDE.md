- NEVER mention "Claude Code", "Claude", or "Anthropic" in commit messages, PR descriptions, or any content going into git. Do NOT add attribution footers like "Generated with Claude Code" or "Co-Authored-By: Claude" to commits or PRs.
- dont add temporary scripts to git unless its part of a permanent solution and doesnt duplicate existing functionality.
- use a common prefix for throwaway code and add it to gitignore, lets use Temp
- when working on a project, always read README.md first to understand project structure, configuration, and setup instructions

## TaskFlow Usage
- ALWAYS use slash commands (`/tfs`, `/tfl`, `/tfr`, `/tfsync`) or natural language with the taskflow agent
- NEVER use `/taskflow` directly (loads 900-token skill.md)
- When user asks about tasks, status, or task operations, use the agent automatically: `Task(subagent_type="taskflow", ...)`
- Recognize terse requests like "check tasks", "status", "resume UI-007" and use agent or slash commands
- Use `/tfsync` to create/update issues for current work (replaces old `/tfc` session notes)
- Type `/tfhelp` for complete command reference

### CRITICAL: Working Directory Check
**TaskFlow is project-local, not global!** Before ANY TaskFlow operation:
1. Check `pwd` - are you in a project directory or ~/.claude?
2. Verify `ACTIVE.md` exists in current directory
3. If missing: ASK user "Which project directory should I navigate to?"
4. NEVER blindly run TaskFlow commands from ~/.claude or home directory
See: `~/.claude/skills/docs/TASKFLOW-WORKING-DIRECTORY.md` for details