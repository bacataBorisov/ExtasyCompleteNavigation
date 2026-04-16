# Documentation map (humans + AI + Agent OS)

This repo mixes **human-written canon**, **generated Agent OS artifacts**, **Cursor skills**, and **app-local READMEs**. Use this file as the **single index** so nothing important lives only in someone’s head.

---

## 1. Layers (who owns what)

| Layer | Path | Purpose | Commit to git? |
|-------|------|---------|----------------|
| **Project canon** | [`.agent/`](.) | Architecture, roadmap, changelog, conventions, lessons, hardware — **source of truth** for decisions. | Yes |
| **Doc hub (this file)** | `.agent/DOCUMENTATION.md` | How docs are organized; Agent OS tips. | Yes |
| **Agent OS (generated)** | [`.agent-os/`](../.agent-os) | SQLite index, `scanned-summary.md`, `cache.md`, `current-handoff.md`, `exports/context-pack.*` — **machine + session context**. Excluded from its own scan (see `config.json`). | **No** for almost everything: root [`.gitignore`](../.gitignore) ignores `data/`, `context/`, `exports/`, `state/`, `logs/` — **only** [`.agent-os/config.json`](../.agent-os/config.json) is meant to be committed |
| **Agent OS entry** | [root `AGENT_OS.md`](../AGENT_OS.md) | Xcode-friendly pointer; **may be rewritten** by `agentos` CLI. | Yes |
| **Cursor skills** | [`.cursor/skills/`](../.cursor/skills) | Reusable agent instructions (e.g. sailing tactics). **Indexed** unless you exclude `.cursor`. | Yes |
| **Public / onboarding** | [root `README.md`](../README.md) | Videos, high-level pitch, link into `.agent/`. | Yes |
| **App module README** | `ExtasyCompleteNavigation/README.md` | Module layout for developers **inside** the Xcode tree. | Yes |
| **Guides (how-tos)** | [`.agent/guides/`](guides/) | Longer procedural docs (e.g. core math test path). Same commit policy as `.agent/`. | Yes |
| **Cursor agent entry** | [root `AGENTS.md`](../AGENTS.md) | Short “read this first” for Cursor; not edited by `agentos` by default. | Yes |
| **Polar / VPP source** | `ExtasyCompleteNavigation/Resources/*.pdf`, `diagram.txt`, … | Authoritative performance data, not prose architecture. | Yes |
| **Build noise** | `.build/`, `DerivedData/`, `*.xcuserstate` | Should **not** drive architecture narrative. **Exclude from Agent OS scan** (see below). | No / gitignored |

---

## 2. `.agent/` file roles (read order for new contributors)

1. **[PROJECT.md](PROJECT.md)** — What the system is, data flow, key files, NMEA table, Agent OS refresh commands.  
2. **[CONVENTIONS.md](CONVENTIONS.md)** — Code style and patterns.  
3. **[Guides](guides/)** — Optional deep dives (e.g. [`guides/testing-core-math.md`](guides/testing-core-math.md)).  
4. **[ROADMAP.md](ROADMAP.md)** — Prioritized work.  
5. **[CHANGELOG.md](CHANGELOG.md)** — What changed, session notes.  
6. **[LESSONS.md](LESSONS.md)** — Pitfalls and “why we did X”.  
7. **[HISTORY.md](HISTORY.md)** / **[HARDWARE.md](HARDWARE.md)** — Context as needed.

**Session handoff (next task / context for agents):** Use **Agent OS** outputs — primarily **[`.agent-os/state/current-handoff.md`](../.agent-os/state/current-handoff.md)** (and **`cache.md`**, **`exports/context-pack.*`**). They are **generated locally** (see §3); refresh with `agentos handoff update` or `agentos init .`. **Do not** maintain a separate committed handoff file under `.agent/`; policy detail is in **§3** (“Maintainer preference”).

**Rule of thumb:** If it’s a **decision or architecture**, it belongs in `.agent/`, not only in a chat. **Session handoff** belongs in the **Agent OS** pipeline, not duplicated as ad-hoc canon.

---

## 3. Agent OS (`agentos` / `agentos-scan`) — how it fits

- **Scan** builds an index of the repo (paths, chunks) into `.agent-os/data/`.  
- **`cache.md` / `current-handoff.md` / `context-pack.*`** summarize what’s relevant for the **next** agent session.  
- **Problem:** If the scan includes **build products** (`.build/`, SPM artifacts, headers), **handoff and exports get polluted** with hundreds of irrelevant paths — worse answers and wasted tokens.

### Why Agent OS files look “empty” or never change in git

1. **They are not in version control (by design).** After `agentos cache update` / `handoff update` / `export`, files under `.agent-os/state/`, `context/`, `exports/`, and `data/` update **on your machine only**. `git status` stays clean because those paths are **gitignored** — only `.agent-os/config.json` is tracked. Clones and PRs will not carry your regenerated handoff or context pack unless you change that policy.

2. **`cache update` does not re-scan the repo.** Those commands **read the existing SQLite DB** and rewrite Markdown/JSON. They do **not** walk the tree again. To pick up new/changed source files or new `exclude_dirs`, run **`agentos init .`** from the repo root (full scan + cache + handoff + export), or run the underlying **`agentos-scan scan`** then the lighter `agentos cache update && agentos handoff update && agentos export`.

3. **Human slots stay blank until you fill them.** Templates in `state/cache.md` (e.g. “Current objective”, “Immediate next step”) are for **you** to edit; the CLI mainly appends scan-derived sections (and may leave them sparse when there is nothing new to report).

4. **If `current-handoff.md` lists `.build/` or other junk**, the index was created or incrementally updated while those paths were still indexed. Fix exclusions in `config.json`, then run **`agentos init .`** so the DB is rebuilt from a clean scan. If `.build` still appears, **delete the local `.build/` folder** (SwiftPM output) and run **`agentos init .`** again — some scans still pick up on-disk build trees despite `exclude_dirs`.

5. **`AGENT_OS.md` is regenerated** by `agentos init` / some other commands. Do not rely on it for repo-specific prose that must survive a refresh; keep that in **`.agent/DOCUMENTATION.md`** (this file) or **`AGENTS.md`**.

### Recommended `config.json` practice

Keep `exclude_dirs` tight for anything that is **regenerable** or **not source**:

- Always: `.git`, `node_modules`, `.agent-os` (self-exclusion).  
- Add: **`.build`** (SwiftPM local build tree at repo root).  
- Consider: `DerivedData` if ever present inside the repo; large `xcuserdata` trees are better **gitignored** than scanned (see root `.gitignore`).

After editing exclusions, run a **full** refresh so the DB is rescanned:

```bash
agentos init .
```

For day-to-day work **when the index is already healthy**, a lighter pass is enough:

```bash
agentos cache update && agentos handoff update && agentos export
```

### What to **not** put in Agent OS as “truth”

Generated files under `.agent-os/` **summarize** the repo; they are not a substitute for **`.agent/PROJECT.md`**. When something is wrong in a summary, **fix the source doc** in `.agent/` and re-scan.

### Maintainer preference: handoff and new files (Agent OS compliance)

This project **uses Agent OS for handoff**, not a parallel Markdown file in `.agent/`.

- **Handoff:** Rely on **`.agent-os/state/current-handoff.md`** (plus **`cache.md`** and **`exports/`** as needed). Regenerate after meaningful work: `agentos cache update && agentos handoff update && agentos export`, or **`agentos init .`** when the index or **`config.json`** `exclude_dirs` changes.
- **New files:** If something belongs to **indexing, session context, or exports**, add or adjust it **in compliance with Agent OS** — typically **[`.agent-os/config.json`](../.agent-os/config.json)** (scan rules), then regenerate; do not invent a second handoff system under `.agent/`. **Human canon** (architecture, changelog, roadmap) stays in **`.agent/`** per §1.
- **Git:** Only **`config.json`** (and similar committed hooks) are tracked; generated `.agent-os/` trees remain **gitignored** by design.

---

## 4. Layout choices applied in this repo

- **Two READMEs:** Root [`README.md`](../README.md) = public story; [`ExtasyCompleteNavigation/README.md`](../ExtasyCompleteNavigation/README.md) = module map — each links to the other at the top.  
- **Guides:** Former `ai/docs/testing-core-math.md` now lives at **[`guides/testing-core-math.md`](guides/testing-core-math.md)**; the `ai/` tree was removed.  
- **Scratch notebooks:** Root `Untitled.ipynb` removed; **`.gitignore`** ignores `Untitled.ipynb`, `.ipynb_checkpoints/`, `.virtual_documents/`.  
- **Cursor:** Root **[`AGENTS.md`](../AGENTS.md)** points agents at `.agent/` first.  
- **Agent OS scan:** [`.agent-os/config.json`](../.agent-os/config.json) excludes `.build`, `DerivedData`, and Jupyter scratch dirs (see `exclude_dirs`).  

If you later need a public **`docs/`** tree (e.g. compliance PDFs), add it at the repo root and link it here — keep **engineering** truth in `.agent/`.

---

## 5. Quick checklist when adding a new document

- [ ] Is it **canonical**? → `.agent/` or `.agent/guides/` (and link from `README.md` if onboarding-critical).  
- [ ] Is it **Cursor-only**? → `.cursor/rules/` or `.cursor/skills/`.  
- [ ] Is it **generated**? → `.agent-os/` only; do not hand-edit as source of truth.  
- [ ] Is it **handoff / session context**? → **Agent OS** (`current-handoff.md`, etc.); do **not** add a new `.agent/HANDOFF.md`-style file — use **`agentos handoff update`** or **`agentos init .`**.  
- [ ] Will **scans** pick up junk? → Update `.agent-os/config.json` `exclude_dirs`, then **`agentos init .`** (not `cache update` alone).

---

## 6. Related paths

- [Root README](../README.md) — public overview.  
- [App target README](../ExtasyCompleteNavigation/README.md) — folder map inside Xcode.  
- [`AGENTS.md`](../AGENTS.md) — Cursor / agent entry.  
- [AGENT_OS.md](../AGENT_OS.md) — Agent OS paths & Xcode note.  
- [`.agent-os/config.json`](../.agent-os/config.json) — scan exclusions.
