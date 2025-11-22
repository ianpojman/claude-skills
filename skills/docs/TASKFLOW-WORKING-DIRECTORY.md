# TaskFlow Working Directory Guide

## Critical Context Awareness Issue

### Problem Pattern

When a user says:
- "continue with PERF-009"
- "resume TASK-ID"
- "check tasks"

And you're in the **wrong directory**, you'll get confusing errors like:
```
grep: ACTIVE.md: No such file or directory
ls: docs/active/: No such file or directory
❌ Task file not found: docs/active/PERF-009.md
```

### Root Cause

**TaskFlow operates in PROJECT directories, not ~/.claude!**

The scripts expect:
```
/path/to/project/
├── ACTIVE.md
├── BACKLOG.md
├── docs/
│   ├── active/
│   │   ├── PERF-009.md
│   │   └── UI-007.md
│   └── session-notes/
└── .taskflow-session.json
```

### Solution Workflow

**BEFORE running any TaskFlow command, verify working directory:**

1. **Check where you are:**
   ```bash
   pwd
   ```

2. **If in ~/.claude or user home:**
   - **STOP** - Don't run TaskFlow commands yet
   - **ASK the user**: "Which project should I work on?" or "Where is your project directory?"
   - Examples:
     - "I'm currently in ~/.claude. Which project directory contains PERF-009?"
     - "Could you tell me the project path where you're tracking this task?"

3. **Once you have the project path:**
   ```bash
   cd /path/to/project
   /tfr PERF-009  # Now this will work
   ```

### Detection Pattern

**Indicators you're in the wrong directory:**

1. `pwd` returns:
   - `/Users/username`
   - `/Users/username/.claude`
   - Any path WITHOUT project-specific files

2. Missing TaskFlow files:
   ```bash
   ls ACTIVE.md       # No such file
   ls docs/active/    # No such file
   ```

3. The user references a task ID (PERF-009, UI-007, etc.) but you have no context about it

### Correct Response Pattern

❌ **DON'T DO THIS:**
```
User: "continue with PERF-009"
Agent: /tfr PERF-009
[Error: ACTIVE.md not found]
Agent: [tries find/grep commands searching entire filesystem]
```

✅ **DO THIS:**
```
User: "continue with PERF-009"
Agent: [checks pwd, sees ~/.claude or /Users/username]
Agent: "I'm currently in ~/.claude. Which project directory should I navigate to for PERF-009?
       Is it in a specific codebase or repository?"
```

### Smart Context Recovery

If the user mentions a task but you're in the wrong directory:

1. **Search for recent projects** (if appropriate):
   ```bash
   # Look for recent git repos with TaskFlow
   find ~/projects -name "ACTIVE.md" -type f 2>/dev/null
   ```

2. **Check git status** for clues:
   ```bash
   git status  # Are we even in a git repo?
   ```

3. **Ask the user directly** - this is the fastest solution:
   > "I don't see ACTIVE.md in the current directory. Could you provide the path to the project where you're tracking PERF-009?"

### Common Scenarios

#### Scenario 1: Fresh session, user jumps right in
```
User: "resume PERF-009"
Agent: [pwd check] → /Users/ipojman
Agent: "Which project directory is PERF-009 in? I'm currently at your home directory."
```

#### Scenario 2: Working in ~/.claude config
```
User: "continue with ETL-003"
Agent: [pwd check] → /Users/ipojman/.claude
Agent: "I'm in the Claude config directory. Should I navigate to your project?
       What's the path to the project with ETL-003?"
```

#### Scenario 3: Multiple projects
```
User: "status on tasks"
Agent: [ls check] → no ACTIVE.md
Agent: "I don't see TaskFlow files here. Which project's tasks do you want to check?
       Examples: ~/work/data-pipeline, ~/projects/web-app"
```

### Integration with Agent Instructions

When implementing taskflow agent calls, add this check:

```python
# Pseudo-code for agent decision-making
if user_mentions_task_id:
    current_dir = run("pwd")
    has_active_md = check_file_exists("ACTIVE.md")

    if not has_active_md:
        ask_user("Which project directory should I navigate to?")
    else:
        proceed_with_taskflow_command()
```

### Prevention Tips

1. **Always check `pwd` first** when user mentions task IDs
2. **Look for ACTIVE.md** before running TaskFlow commands
3. **Ask clarifying questions** rather than searching blindly
4. **Learn project paths** from user responses and remember them in context
5. **Suggest navigation** if you discover the project location

### Quick Checklist

Before running `/tfr`, `/tfs`, `/tfl`, or any TaskFlow command:

- [ ] Run `pwd` - am I in a project directory?
- [ ] Check `ls ACTIVE.md` - does TaskFlow exist here?
- [ ] If no: ASK user for project path
- [ ] If yes: Proceed with command

---

**Remember:** TaskFlow is project-local, not global. Always verify working directory before operation.
