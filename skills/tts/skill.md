# TTS - Text-to-Speech Coaching

**macOS `say` command for announcing key findings and milestones.**

## Core Pattern (ALWAYS use this)

```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/[SOUND].aiff && say -v "Ava (Premium)" "Message"
```

## Quick Controls

```bash
touch ~/.tts_paused    # Pause TTS
rm -f ~/.tts_paused    # Resume TTS
```

## When to Use

✅ **Use**: Discoveries, completions, errors, performance wins, milestones
❌ **Skip**: Normal steps, routine operations, every file operation

## Common Sounds

- **Glass** - Success, completions
- **Pop** - Errors, warnings
- **Blow** - Default status
- **Funk** - Progress milestones
- **Purr** - Discoveries

## Pronunciation Guide

AWS → "A W S" | EMR → "E M R" | S3 → "S 3" | Parquet → "Par kay"

## Examples

**Success**:
```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Glass.aiff && say -v "Ava (Premium)" "Build succeeded. All 156 tests passed."
```

**Error**:
```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Pop.aiff && say -v "Ava (Premium)" "Build failed. Three compilation errors found."
```

**Discovery**:
```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Purr.aiff && say -v "Ava (Premium)" "Found root cause in parser, line 847."
```

---

**Keep it concise**: 1-2 sentences max. Quality over quantity.
