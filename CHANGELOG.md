# Changelog

All notable changes to Claude Skills will be documented in this file.

## [1.1.0] - 2025-11-20

### Added - TaskFlow Major Update

**New Features:**
- ✨ **Project Activation System**: `.taskflow` marker for opt-in/opt-out per project
- 🔍 **Auto-detection**: Automatically activates if TODO.md + BACKLOG.md structure exists
- 📋 **Smart Hook Integration**: Hooks check activation before running
- 📊 **Token Budget Awareness**: SessionStart shows token status when active
- 💬 **Context-Aware Loading**: UserPromptSubmit intelligently loads TODO.md on demand
- 📝 **Handoff Command**: New `taskflow handoff` for session continuity (work-in-progress)

**Documentation:**
- Added `TASKFLOW.md` activation guide
- Updated skill documentation with activation instructions
- Clarified generic vs project-specific components

**Token Optimization:**
- Active projects: ~3-5% overhead (smart loading)
- Inactive projects: <1% overhead (pure passthrough)
- SessionStart: Auto-detects and adapts behavior

**Hook Improvements:**
- Generic, project-agnostic messaging
- Graceful degradation when TaskFlow not active
- Clear activation prompts for new projects

### Changed
- SessionStart hook now checks for `.taskflow` before activating
- UserPromptSubmit hook passes through silently when TaskFlow inactive
- Simplified borders and messaging for better terminal compatibility

### Fixed
- Removed hardcoded project-specific names from hooks
- Made hooks respect project activation state

## [1.0.0] - 2025-11-20

### Initial Release

**Skills Included:**
- 🎯 **TaskFlow**: Token-efficient task management
  - Archive system for completed items
  - Token budget enforcement (TODO: 2K, BACKLOG: 10K)
  - Link validation
  - Status synchronization
  - Context capture from conversations

- 🔊 **TTS**: Text-to-speech announcements
  - macOS `say` integration
  - Pause/resume controls
  - Volume management
  - Sequential audio output

- ⚡ **Spark Optimization**: EMR/Spark debugging
  - Container log analysis
  - Memory/OOM debugging
  - Partition optimization
  - Cost optimization strategies

**Standalone Scripts:**
- `taskflow-analyze.sh`: Token usage analysis
- `taskflow-validate.sh`: Link validation

**Repository:**
- Public GitHub repository: https://github.com/ianpojman/claude-skills
- MIT License
- Installation instructions
- Comprehensive README
