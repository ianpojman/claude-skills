# TaskFlow Working Directory Guide

## External Directory Architecture

**TaskFlow files are stored externally, NOT in project directories.**

```
~/.taskflow/
├── project-name-1/
│   ├── ACTIVE.md
│   ├── BACKLOG.md
│   ├── .taskflow-session.json
│   └── docs/
│       ├── active/
│       ├── backlog/
│       └── handoff/
├── project-name-2/
│   └── ...
└── another-project/
    └── ...
```

### How It Works

1. **Auto-detection**: When you run TaskFlow commands, they detect your project via `git rev-parse --show-toplevel`
2. **Slug generation**: Project directory name becomes the slug (e.g., `/path/to/my-project` → `~/.taskflow/my-project/`)
3. **Auto-creation**: External directory is created automatically on first use

### Benefits

- TaskFlow files stay out of your git repository
- No commits of AI-generated task management to shared repos
- Clear separation between codebase and task tracking
- Easy to back up all TaskFlow data in one place

## Usage

### From Any Project Subdirectory

```bash
# Works from anywhere in a git repo
cd /path/to/my-project/src/components
~/.claude/skills/scripts/taskflow-status.sh
# → Uses ~/.taskflow/my-project/
```

### Multiple Projects

Each git repository gets its own TaskFlow directory:

```bash
cd ~/work/project-a
/tfs  # → ~/.taskflow/project-a/

cd ~/work/project-b
/tfs  # → ~/.taskflow/project-b/
```

### Setup for New Projects

```bash
# Option 1: Automatic on first TaskFlow command
/tfs  # Creates ~/.taskflow/{project-name}/ if needed

# Option 2: Explicit setup
~/.claude/skills/scripts/taskflow-setup.sh
```

### Migration from In-Project Files

If you have existing TaskFlow files in your project:

```bash
~/.claude/skills/scripts/taskflow-migrate-to-external.sh
```

This moves ACTIVE.md, BACKLOG.md, docs/active/, etc. to `~/.taskflow/{project-name}/`

## Edge Cases

### Not in a Git Repository

If you're not in a git repository, TaskFlow uses `pwd` as the project root.

```bash
cd /tmp/scratch
/tfs  # → ~/.taskflow/scratch/
```

### Wrong Project Detection

If the wrong project is detected, you can:

1. Check what's detected: `git rev-parse --show-toplevel`
2. Navigate to the correct directory
3. Run TaskFlow commands from there

## Quick Reference

| Scenario | What Happens |
|----------|--------------|
| In git repo root | Uses that directory's name for TaskFlow slug |
| In git repo subdirectory | Auto-detects root, uses root directory name |
| Not in git repo | Uses current directory name |
| First use in new project | Creates `~/.taskflow/{slug}/` automatically |

---

**Key Point:** You don't need to manage TaskFlow file locations manually. Just run TaskFlow commands from within your project (any subdirectory works), and files are automatically stored in `~/.taskflow/`.
