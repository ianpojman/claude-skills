# Claude Crash Recovery - Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║         CLAUDE CRASH RECOVERY - QUICK GUIDE              ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  BEFORE CRASH (do this early!):                          ║
║                                                           ║
║    /name session-name     ← Name your session            ║
║    /save                  ← Save state regularly          ║
║                                                           ║
║  ─────────────────────────────────────────────────────   ║
║                                                           ║
║  AFTER CRASH/FREEZE:                                     ║
║                                                           ║
║    1. /sessions           ← See saved sessions           ║
║    2. /resume session-name ← Get back to work            ║
║                                                           ║
║  ─────────────────────────────────────────────────────   ║
║                                                           ║
║  QUICK STATUS CHECK:                                     ║
║                                                           ║
║    /tfs                   ← Shows session name + tasks   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

## The 4 Commands You Must Memorize

1. **`/name`** - Name your session
   - Example: `/name perf-work`
   - Do this at the START of work!

2. **`/save`** - Save your session
   - Run periodically
   - Outputs ONE command to resume later

3. **`/sessions`** - List available sessions
   - Use after crash to see what you have

4. **`/resume`** - Restore your session
   - Example: `/resume perf-work`
   - Gets you back to work immediately

## Typical Crash Recovery Flow

```
┌─────────────────────────────────────────────┐
│ Session 1 (before crash)                    │
├─────────────────────────────────────────────┤
│ You:   /name cache-feature                  │
│ You:   /tfstart PERF-009                    │
│ You:   ... working ...                      │
│ You:   /save                                │
│ Output: ✅ To resume: /resume cache-feature │
│                                             │
│ [Claude freezes from large paste]           │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Session 2 (new window)                      │
├─────────────────────────────────────────────┤
│ You:   /sessions                            │
│ Output: - cache-feature                     │
│         - ui-fixes                          │
│         - perf-optimization                 │
│                                             │
│ You:   /resume cache-feature                │
│ Output: 📋 Tasks in session:                │
│         1. PERF-009: Cache Browser UI       │
│         Choose task to continue...          │
│                                             │
│ [You're back to work!]                      │
└─────────────────────────────────────────────┘
```

## Common Crash Triggers

Claude often freezes when:
- Near token limit AND pasting large text/images
- Multiple large file reads in rapid succession
- Heavy computation + user interaction

**Prevention**: Name and save your session BEFORE risky operations!

## Session Naming Tips

✅ **Good names** (short & memorable):
- `cache-feature`
- `perf-work`
- `ui-fixes`
- `bug-auth`

❌ **Bad names** (hard to remember/type):
- `my-very-long-descriptive-session-name`
- `session1`, `work`, `stuff`
- `2025-11-21-feature-work-session`

## Alternative Commands (same functionality)

All these work the same way - use whichever you remember:

| Short | Long | Purpose |
|-------|------|---------|
| `/name` | `/tfsname` | Name session |
| `/save` | `/tfhandoff` | Save session |
| `/sessions` | `/tflist` | List sessions |
| `/resume` | `/tfresume` | Resume session |
| `/tasks` | `/tfl` | List tasks |

Use the **short** versions for speed during crashes!

## Emergency Recovery (if you forgot to save)

If Claude crashed and you didn't run `/save`:

1. Check if session auto-saved: `/sessions`
2. Look for auto-generated names (timestamps)
3. Resume the most recent: `/resume 2025-11-21-1730`

**Lesson**: Always `/name` and `/save` early in your session!

## Print This Card

Keep this handy for when you're under stress and can't remember commands.

**The Recovery Mantra:**
> "Name it early, save it often, resume by name."
