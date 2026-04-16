# Agent instructions (Cursor / automation)

When working in this repository:

1. Read **[`.agent/PROJECT.md`](.agent/PROJECT.md)** for architecture, data flow, and NMEA handling.
2. Read **[`.agent/CONVENTIONS.md`](.agent/CONVENTIONS.md)** before changing Swift or UI patterns.
3. Use **[`.agent/DOCUMENTATION.md`](.agent/DOCUMENTATION.md)** for where docs live (human canon vs `.agent-os/` generated vs Cursor skills).
4. Prefer **[`.agent/ROADMAP.md`](.agent/ROADMAP.md)** and **[`.agent/CHANGELOG.md`](.agent/CHANGELOG.md)** for scope and recent decisions. For **session handoff**, use **Agent OS** — **[`.agent-os/state/current-handoff.md`](.agent-os/state/current-handoff.md)** (local; regenerate with `agentos handoff update` or `agentos init .`). Policy: **[`.agent/DOCUMENTATION.md`](.agent/DOCUMENTATION.md)** §3 (“Maintainer preference”).

**Agent OS:** generated output under **`.agent-os/`** is **gitignored** (only `config.json` is committed), so `agentos cache update` updates **local** files only — **`git status` will not show it.** Use **`agentos init .`** for a full rescan; `cache update` alone rewrites Markdown from the **existing** DB. **`AGENT_OS.md`** is often rewritten by the CLI; details live in **[`.agent/DOCUMENTATION.md`](.agent/DOCUMENTATION.md)** §3.

**Math / package tests:** **[`.agent/guides/testing-core-math.md`](.agent/guides/testing-core-math.md)**.

Do not treat `.agent-os/state/*.md` or exports as authoritative over `.agent/` when they disagree — fix the source in `.agent/`.
