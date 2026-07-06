---
description: Generate HTML session report, save to iCloud, and open in browser
---

Generate an HTML report for the current session's work and open it locally. Same report syncs to iCloud for mobile access.

Use `/mobileReport` instead when working from a remote terminal where `open` won't reach a local display.

## Instructions

1. **Gather context**: Analyze the current conversation for:
   - What was done (chronological)
   - Key decisions and trade-offs
   - The substance of each change — what behavior changed and why, with the relevant code
   - Current state and next steps
   - Also check `tasks/todo.md`, recent git log, and active task docs in `docs/active/`

2. **Determine report name**: Use the session slug or task ID + short descriptor (e.g., `lf-001-link-flow-calendar.html`, `dq-052-ingestion-fix.html`). Include today's date if no task ID: `2026-03-01-perf-tuning.html`.

3. **Generate HTML**: Create a themeable, mobile-optimized HTML report using the shared theme framework:
   - Set the root element: `<html lang="en" data-theme="carbon" data-choice="auto">`.
   - **Inline the theme framework** from `~/.claude/report-theme.html` (read it; it's marked into three blocks): put `THEME:STYLE` in `<head>`, `THEME:BODY` as the first child of `<body>`, and `THEME:SCRIPT` just before `</body>`. Do NOT hand-roll colors — use the framework's layout classes (documented at the bottom of that file).
   - Theme UX: no visible widget; the user presses ⌘K / Ctrl+K to switch themes (Auto = Aperture light / Carbon dark, persisted in localStorage). Add a footer hint: `Press <kbd>⌘K</kbd> to change theme.`
   - Content sections (use the class vocabulary): header (`.eyebrow`, `h1` with an optional `.grad` keyword, `.lede`, `.status`), a `.kpis` strip of `.kpi` cards, Context (the "why"), The changes (see below), Key decisions with rationale (table or `.callout`), Verification (table with `.ok-t/.warn-t/.bad-t`), Next steps (`ul.plain`), and a `.meta` footer (date, branches, repos).
   - **The changes — substance over inventory.** Do NOT end the report with a bare list of modified files; that inventory is rarely useful on its own. Instead, describe each meaningful change: what behavior changed, why, and the interesting part of the diff as a code snippet (`.code` block, trimmed to the lines that matter). A filename should only ever appear attached to its snippet or explanation — never as a standalone bullet. `ul.files` + `.tag` markup is still fine as the *container* for these entries, but each entry carries a one-to-two sentence explanation plus a trimmed code snippet (5–20 lines, just the interesting part of the diff). **Code samples are REQUIRED for every substantive change — this is the report's core value, not decoration** (established format: user confirmed 2026-07-05). Trivial/mechanical changes (formatting, version bumps, doc pointers) can be summarized in one line collectively, no snippet needed.
   - **Wide content must not clip.** Architecture diagrams, inline SVG figures, and tables with many columns are wider than the `.wrap` reading column — wrap diagrams/figures in `<div class="wide">` (full-bleed breakout) and wide tables in `<div class="scrollx">` (horizontal-scroll container); a very wide table can use both. Any inline SVG must use a `viewBox` and scale with `width:100%` — never a fixed pixel width/height — so it shrinks to fit on mobile and stretches to fill `.wide` on desktop.

4. **Save to iCloud**: Write the file to `~/Library/Mobile Documents/com~apple~CloudDocs/HERE/`

5. **Open locally**: Run `open <icloud-path>` to open in the default browser. This is the key difference from `/mobileReport` — you see it immediately if you're at the machine.

6. **Report the path**: Tell the user the iCloud path and confirm it opened.

## Style Reference

All styling comes from the shared theme framework at `~/.claude/report-theme.html` — inline its three blocks verbatim (see step 3). That file is the **single source of truth** for the palette and layout, shared with the in-app theme framework (THEME-FRAMEWORK-001) so reports and the consoles look identical.

- **Themes** (selectable via ⌘K): Auto (default; Aperture-light / Carbon-dark), Soft dark (Slate, Carbon, Dim, Dusk), Deep dark (Graphite, Aurora, Indigo, Teal, Amber, Mono), Light (Aperture, Paper).
- **Layout classes** (do not invent new colors; use the CSS vars/classes): `.wrap` (max-width 980), `.eyebrow`, `h1`/`.grad`, `.lede`, `.status`/`.dot`, `.kpis`/`.kpi`/`.n`/`.l`, `h2`/`h3`, `.callout`(`.bug`/`.ok`), `ul.files`/`.tag`(`.t-fix`/`.t-cfg`/`.t-del`/`.t-mem`)/`.fp`, `.code`/`code`/`.pill`/`<kbd>`, tables with `.ok-t`/`.warn-t`/`.bad-t`, `ul.plain`, `.meta`, `.wide` (full-bleed breakout for diagrams/figures), `.scrollx` (horizontal-scroll container for wide tables).
- To tweak the palette/effects later, edit `~/.claude/report-theme.html` once and every future report inherits it.
