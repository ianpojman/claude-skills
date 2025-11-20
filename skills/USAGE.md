# TaskFlow Usage Guide

**Token-efficient task management using agents and scripts.**

## Quick Reference

| Use Case | Command | Method | Tokens |
|----------|---------|--------|--------|
| **Quick status** | `~/.claude/skills/scripts/taskflow-status-minimal.sh` | Script | 0 |
| **Analyze tokens** | "Analyze taskflow token usage" | Agent | 0 |
| **Capture session** | "Capture this session to taskflow" | Agent | 0 |
| **Create handoff** | "Create taskflow handoff" | Agent | 0 |
| **Compact ACTIVE** | `~/.claude/skills/scripts/taskflow-compact-active.sh` | Script | 0 |
| **Resume task** | `~/.claude/skills/scripts/taskflow-resume.sh TASK-ID` | Script | 0 |

⚠️ **Important**: Don't say "taskflow status" or "taskflow X" - this invokes the skill and wastes tokens! Either run scripts directly or use natural language for agent operations.

## Key Principle: Scripts vs Agents

**Scripts** (Fast, 0 tokens):
- Quick status checks
- Simple operations
- Known commands
- Direct execution

**Agents** (Comprehensive, isolated context):
- Complex analysis
- Session capture
- Handoff generation
- Multi-step operations

---

## Core Workflows

### 1. Session Start

**Quick status check using script** (0 tokens):

**Direct execution** (recommended):
```bash
~/.claude/skills/scripts/taskflow-status-minimal.sh
```

**Or create alias** in `~/.bashrc`/`~/.zshrc`:
```bash
alias tfs='~/.claude/skills/scripts/taskflow-status-minimal.sh'
```

**⚠️ Don't say "taskflow status"** - this invokes the skill and wastes tokens!

Output:
```
📊 18 active tasks | feature/branch@abc123 ⚠️ | ACTIVE 2094tok | BACKLOG 1091tok
```

**If resuming specific task**:
```bash
taskflow resume PARQ-003
```

---

### 2. Task Analysis & Cleanup

**Use the TaskFlow agent** for comprehensive analysis:

**Natural language** (recommended):
```
Analyze taskflow token usage and suggest what to archive
```

Behind the scenes, I'll invoke:
```python
Task(
    subagent_type="taskflow",
    description="Analyze token usage",
    prompt="Run taskflow analyze, report ACTIVE/BACKLOG token counts, and suggest archival candidates"
)
```

**Agent will**:
- Run `~/.claude/skills/scripts/taskflow-analyze.sh`
- Analyze token distribution
- Identify session notes > 3 days old
- Recommend archival actions
- Report back to main context

---

### 3. Session Capture

**After debugging, discoveries, or completing work**, capture insights using agent:

**Natural language**:
```
Capture this session to taskflow - we fixed the geometry duplicates issue
```

Behind the scenes:
```python
Task(
    subagent_type="taskflow",
    description="Capture session insights",
    prompt="Run taskflow capture with summary: 'Fixed GEO-001 geometry duplicates. Root cause: WKB join not handling bidirectional links. Solution: Added direction normalization.'"
)
```

**Agent will**:
- Create timestamped session note in ACTIVE.md
- Extract key discoveries
- Link to relevant tasks
- Keep under token budget

---

### 4. Session Handoff

**When work is incomplete** and you need to hand off to future session/agent:

**Natural language**:
```
Create a taskflow handoff - cluster is running, waiting for validation
```

Behind the scenes:
```python
Task(
    subagent_type="taskflow",
    description="Generate session handoff",
    prompt="Create handoff document. Current state: EMR cluster j-XYZ running for 45min, validation step in progress. Next: Check stderr for completion, validate WKB failure count < 1000."
)
```

**Agent creates SESSION-*.md with**:
- Current state (running processes, clusters, etc.)
- What was accomplished
- What needs doing next
- Quick validation commands
- File references

---

### 5. Weekly Maintenance

**Quick compact** (script):
```bash
taskflow compact active
```

**Or comprehensive via agent**:
```
Run taskflow maintenance: analyze, compact, and validate links
```

Agent will:
1. Analyze token usage
2. Archive old session notes
3. Validate all links in ACTIVE/BACKLOG
4. Report any issues

---

## File Structure

```
ACTIVE.md (2K limit)
├── Task index (1K)
└── Recent session notes (1K)

BACKLOG.md (10K limit)
└── Category index

docs/
├── active/
│   ├── GEO-001.md (5K) ← Load on-demand
│   └── PARQ-003.md (5K)
├── backlog/
│   ├── parquet-and-data-pipeline.md (3K)
│   └── emr-infrastructure.md (2K)
└── session-notes/
    └── 2025-11-20.md ← Archived notes
```

**Token strategy**:
- Session startup: 3K (ACTIVE + BACKLOG index)
- When resuming task: +5K (task details)
- Agent operations: 0 tokens in main context

---

## Complete Command Reference

### Scripts (Direct Execution - 0 Tokens)

**⚠️ Run these directly from terminal or via Bash tool, NOT via natural language**

```bash
# Status (0 tokens)
~/.claude/skills/scripts/taskflow-status-minimal.sh

# Compact (0 tokens)
~/.claude/skills/scripts/taskflow-compact-active.sh

# Resume (0 tokens)
~/.claude/skills/scripts/taskflow-resume.sh TASK-ID

# Recommended: Create aliases in ~/.bashrc or ~/.zshrc
alias tfs='~/.claude/skills/scripts/taskflow-status-minimal.sh'
alias tfc='~/.claude/skills/scripts/taskflow-compact-active.sh'
alias tfr='~/.claude/skills/scripts/taskflow-resume.sh'
```

### Agent Operations (Via Natural Language)

**Analysis**:
```
"Analyze taskflow token usage"
"What can we archive from ACTIVE.md?"
"Run taskflow maintenance"
```

**Capture**:
```
"Capture this session to taskflow"
"Document this debugging session"
"Add session notes about the geometry fix"
```

**Handoff**:
```
"Create a taskflow handoff"
"Generate session handoff document"
"Prepare handoff for next session"
```

**Search**:
```
"Search taskflow for 'geometry duplicates'"
"Find all references to PARQ-003"
```

**Validation**:
```
"Validate taskflow links"
"Check for broken links in docs"
```

---

## Best Practices

### ✅ DO

- **Use scripts for quick checks** (status, resume)
- **Use agent for complex operations** (analyze, capture, handoff)
- **Compact regularly** when ACTIVE.md > 2K tokens
- **Capture insights** after debugging/discoveries
- **Create handoffs** for incomplete work
- **Always reference filenames** ("See docs/active/GEO-001.md")

### ❌ DON'T

- Don't load all task details at startup (load on-demand)
- Don't let session notes accumulate (compact every 3 days)
- Don't reference tasks without filename ("See GEO-001" ← bad)
- Don't use agent for simple status checks (overkill)

---

## Troubleshooting

### "Scripts not found"

Ensure symlinks exist:
```bash
ls -la ~/.claude/skills/taskflow/scripts  # Should show symlink to ../scripts
```

If missing:
```bash
cd ~/.claude/skills
ln -s ../scripts taskflow/scripts
```

### "Agent not available"

Check agent location:
```bash
ls ~/.claude/agents/taskflow.md  # Should exist
```

If missing, agent may be disabled or in wrong location.

### "Token budget exceeded"

Run analysis:
```
Analyze taskflow token usage and compact old notes
```

Or manually:
```bash
taskflow compact active
```

---

## Examples

### Example 1: Start work on PARQ-003

```bash
# Quick check
taskflow status

# Load task context
taskflow resume PARQ-003
```

### Example 2: Debug session with capture

```
User: "Fixed the schema bug in PARQ-003. The issue was incorrect byte order handling."