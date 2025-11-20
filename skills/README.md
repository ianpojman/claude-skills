# Claude Code Skills

Personal collection of skills for enhancing Claude Code workflows.

**Version**: 1.1.0
**License**: MIT
**Repository**: https://github.com/ianpojman/claude-skills

## Skills

### 🎯 TaskFlow - Token-Efficient Task Management
**Location**: `taskflow/skill.md`

Manages project documentation and tasks with automatic archival and token optimization.

**Features**:
- Token usage analysis and budget enforcement
- Automatic archiving of completed items
- Context capture from conversations
- Link validation
- Startup reminders with last-run tracking

**Commands**:
```bash
taskflow analyze    # Token usage + archival candidates
taskflow compact    # Archive completed items
taskflow sync       # Status synchronization
taskflow capture    # Create/update from conversation context
taskflow handoff    # Create session handoff for work-in-progress (NEW v1.1)
taskflow validate   # Link integrity checking
```

**Activation** (v1.1+):
```bash
# Enable TaskFlow in a project
touch .taskflow

# Disable TaskFlow
rm .taskflow

# Auto-activates if TODO.md + docs/strategy/BACKLOG.md exist
```

**Token Budgets**:
- TODO.md: 2K tokens
- BACKLOG.md: 10K tokens
- docs/active/*: 5K each
- docs/completed/*: ∞ (never auto-loaded)

### 🔊 TTS - Text-to-Speech Announcements
**Location**: `tts/skill.md`

macOS text-to-speech coaching mode for announcing findings, errors, and milestones.

**Features**:
- Ava (Premium) voice announcements
- Pause/resume for calls
- Volume control
- Sequential (non-overlapping) audio

### ⚡ Spark Optimization
**Location**: `spark-optimization/skill.md`

Expert guidance for debugging Apache Spark/EMR job failures and performance optimization.

**Specialties**:
- Container log analysis
- Memory/OOM debugging
- Partition strategy optimization
- Iceberg migration
- Cost optimization

## Usage

### In Claude Code

Invoke skills by saying:
```
Use the taskflow skill
```

Or reference them in conversation:
```
Help me optimize this Spark job using the spark-optimization skill
```

### Standalone Scripts

Some skills include executable scripts:

**TaskFlow**:
```bash
# From your project root
./scripts/taskflow-analyze.sh
./scripts/taskflow-validate.sh
```

## Installation

Clone this repo to your `~/.claude/skills` directory:

```bash
cd ~/.claude
git clone https://github.com/ianpojman/claude-skills.git skills
```

Or if you already have skills, merge:

```bash
cd ~/.claude/skills
git init
git remote add origin https://github.com/ianpojman/claude-skills.git
git pull origin main
```

## Troubleshooting

### "no such file or directory: ./scripts/taskflow-status.sh"

If you see this error when skills are invoked, the script symlinks are missing. Fix:

```bash
cd ~/.claude/skills
ln -s ../scripts taskflow/scripts
ln -s ../scripts knowledge-capture/scripts
ln -s ../scripts tts/scripts
```

This happens when cloning the repo fresh, as git may not preserve symlinks depending on your configuration.

## Contributing

These are personal skills, but feel free to fork and adapt for your own use!

## Structure

```
~/.claude/skills/
├── README.md
├── ACTIVE.md              # TaskFlow active tasks (auto-generated)
├── BACKLOG.md            # TaskFlow backlog index (auto-generated)
├── scripts/              # Shared scripts for all skills
│   ├── taskflow.sh
│   ├── taskflow-*.sh    # TaskFlow command scripts
│   └── ...
├── taskflow/
│   ├── skill.md
│   └── scripts/         # Symlink to ../scripts
├── knowledge-capture/
│   ├── skill.md
│   └── scripts/         # Symlink to ../scripts
├── tts/
│   ├── skill.md
│   └── scripts/         # Symlink to ../scripts
└── docs/                # TaskFlow documentation (auto-generated)
    ├── active/
    ├── backlog/
    └── session-notes/
```

**Note**: Each skill directory contains a `scripts` symlink pointing to the shared `../scripts` directory. This allows skills to invoke shared scripts when activated.

## License

MIT - Use freely!
