# Agent instructions (Cursor / automation)

When working in this repository:

1. Read **[`.agent/PROJECT.md`](.agent/PROJECT.md)** for architecture, data flow, and NMEA handling.
2. Read **[`.agent/CONVENTIONS.md`](.agent/CONVENTIONS.md)** before changing Swift or UI patterns.
3. Use **[`.agent/DOCUMENTATION.md`](.agent/DOCUMENTATION.md)** for where docs live (human canon vs `.agent-os/` generated vs Cursor skills).
4. Prefer **[`.agent/ROADMAP.md`](.agent/ROADMAP.md)** and **[`.agent/CHANGELOG.md`](.agent/CHANGELOG.md)** for scope and recent decisions.

**Agent OS:** generated index and handoff live under **`.agent-os/`**; refresh from repo root with `agentos init .` or `agentos cache update && agentos handoff update && agentos export`. Entry pointer: **[`AGENT_OS.md`](AGENT_OS.md)**.

**Math / package tests:** **[`.agent/guides/testing-core-math.md`](.agent/guides/testing-core-math.md)**.

Do not treat `.agent-os/state/*.md` or exports as authoritative over `.agent/` when they disagree — fix the source in `.agent/`.
