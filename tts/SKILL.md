---
name: tts
description: Text-to-speech coaching mode that uses macOS 'say' command to announce key findings, results, errors, and milestones using Ava (Premium) voice. Provides guidance for integrating TTS into scripts and ensuring sequential (non-overlapping) audio output.
---

# TTS Coaching Skill

Use macOS `say` command to announce key findings, results, and important information.

## Core Principles

1. **Concise** - 1-2 sentences max, skip long IDs/paths
2. **Sequential** - Use `&&`, never parallel TTS calls
3. **Key findings only** - Important discoveries, not every step
4. **Default voice** - Ava (Premium) or Allison (Enhanced)
5. **Check pause + volume** - Before EVERY TTS call

## Standard TTS Pattern

**ALWAYS use this pattern**:
```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Glass.aiff && say -v "Ava (Premium)" "Your message"
```

## Quick Controls

**Pause** (for calls/meetings):
```bash
touch ~/.tts_paused           # Pause
rm -f ~/.tts_paused           # Resume
```

**Volume**: Control system volume directly using macOS Volume Keys or:
```bash
osascript -e "set volume output volume 20"  # Quiet (20%)
osascript -e "set volume output volume 50"  # Normal (50%)
osascript -e "set volume output volume 80"  # Loud (80%)
```

**Commands**: `tts-pause`, `tts-resume`

## When to Use TTS

✅ **Use for**:
- Discoveries: "Found root cause in parser, line 847"
- Completions: "Build complete. All tests passed"
- Errors: "Build failed. Three compilation errors"
- Performance: "Query optimized. 340 percent faster"
- Milestones: "First successful Iceberg write"

❌ **Don't use for**:
- Normal conversation
- Every step in a process
- Routine file operations
- Acknowledging requests

## Sound Effects

Modern `.aiff` files (use with `afplay`):
- **Glass** - Success, completions, celebrations
- **Tink** - Minimal, cyber mode, status updates
- **Ping** - Info, notifications, deployments
- **Pop** - Errors, warnings
- **Purr** - Soft, playful, discoveries

## Voice Selection

**Available voices**:
- **Ava (Premium)** - Default, warm, professional
- **Allison (Enhanced)** - Alternative premium voice

**Switch voice**:
```bash
# User says "tts voice allison"
test ! -f ~/.tts_paused && say -v "Allison (Enhanced)" "Switching to Allison enhanced voice."
```

## Modes (Brief)

- **premium** (default) - Professional, high-quality
- **dramatic** - Glass/Pop sounds for builds/tests
- **fun** - Playful with Purr/Ping sounds
- **cyber** - Futuristic with Tink sounds
- **celebration** - Glass sounds for major wins

**Mode switching**:
```bash
# User says "tts mode cyber"
test ! -f ~/.tts_paused && say -v "Ava (Premium)" "Switching to cyber mode"
```

## Pronunciation

- AWS → "A W S"
- EMR → "E M R"
- S3 → "S 3"
- TrafficML → "Traffic M L"
- Parquet → "Par kay"
- DuckDB → "Duck D B"

## Session Init

**At skill activation**:
```bash
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Tink.aiff && say -v "Allison (Enhanced)" "T T S mode activated. Premium voice enabled."
```

## Integration in Scripts

**Bash**:
```bash
if [ $EXIT_CODE -eq 0 ]; then
  test ! -f ~/.tts_paused && say -v "Ava (Premium)" "Job succeeded"
else
  test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Pop.aiff && say -v "Ava (Premium)" "Job failed"
fi
```

**Python**:
```python
import subprocess
def tts(msg, voice="Ava (Premium)"):
    vol = subprocess.run(["cat", "~/.tts_volume"], capture_output=True, text=True).stdout.strip() or "50"
    subprocess.run(["say", f"--volume={vol}", "-v", voice, msg])
```

## Best Practices

1. **Skip details**: "Build succeeded" not cluster IDs/paths
2. **Technical terms**: "E M R" not "emr", "S 3" not "s3"
3. **Numbers**: "1 point 2 million" for 1,200,000
4. **Sound + message**: Glass for success, Pop for errors

## Examples

**Build success**:
```bash
VOLUME=$(cat ~/.tts_volume 2>/dev/null || echo "50")
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Glass.aiff && say --volume=$VOLUME -v "Ava (Premium)" "Build succeeded. All 156 tests passed."
```

**EMR job complete**:
```bash
VOLUME=$(cat ~/.tts_volume 2>/dev/null || echo "50")
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Glass.aiff && say --volume=$VOLUME -v "Ava (Premium)" "E M R step completed. Processed 2 point 4 million records."
```

**Error**:
```bash
VOLUME=$(cat ~/.tts_volume 2>/dev/null || echo "50")
test ! -f ~/.tts_paused && afplay /System/Library/Sounds/Pop.aiff && say --volume=$VOLUME -v "Ava (Premium)" "Build failed. Three compilation errors found."
```

---

**Remember**: Pause check + volume + concise message. Quality over quantity.
