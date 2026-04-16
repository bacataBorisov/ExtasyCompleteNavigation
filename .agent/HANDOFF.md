# Session handoff (Extasy Complete Navigation)

**Updated:** 2026-04-16

Use this file when **switching machines or projects** so the next session has durable context. **Agent OS** handoff under `.agent-os/state/` is **local + gitignored**; this file is **committed**.

## Quick pointers

| Topic | Where |
|--------|--------|
| Architecture & NMEA | [PROJECT.md](PROJECT.md) |
| Swift / UI patterns | [CONVENTIONS.md](CONVENTIONS.md) |
| Doc map & Agent OS | [DOCUMENTATION.md](DOCUMENTATION.md) |
| Roadmap | [ROADMAP.md](ROADMAP.md) |
| What changed | [CHANGELOG.md](CHANGELOG.md) — **[Unreleased] — 2026-04-16** |

## Tests (Apr 2026)

- **Fast / CI-friendly (no simulator):** from repo root, `swift test --disable-sandbox` (see [guides/testing-core-math.md](guides/testing-core-math.md)). Optional: `--enable-code-coverage` and `llvm-cov` for **ExtasyNavigationCore** line coverage (~92% library lines after edge-case additions).
- **Full app + iOS:** Xcode, pick a **simulator** (iOS 17/18 per [PROJECT.md](PROJECT.md) device notes), **`⌘U`** (Product → Test). Target **`ExtasyCompleteNavigationTests`** includes **`LaylineTests`**, **`WaypointDataTests`**, extended **`VMGCalculatorTests`**.

## Agent OS refresh (local only)

Regenerates `.agent-os/state/cache.md`, `current-handoff.md`, exports — **not shown in `git status`** (except `config.json`).

```bash
cd /path/to/ExtasyCompleteNavigation
agentos cache update && agentos handoff update && agentos export
```

After changing **exclude_dirs** or large tree moves, prefer a full rescan:

```bash
agentos init .
```

## Recent theme (2026-04-16)

- iPad **map** layout: leading flush, small trailing inset, gap vs instrument column, divider flush to map.
- **WaypointData.reset()** clears **`boatLocation`**; tests aligned.
- Mirrored **core math tests** in **`NavigationCorePackage`** + overlapping cases in **app test target**.

## Cursor memory

There is no separate “memory” store in-repo; **`AGENTS.md`** at the repo root is the Cursor entry; skills live under **`.cursor/skills/`**.
