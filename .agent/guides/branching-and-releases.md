# Branching & Release Strategy

> Established: 2026-05-11, after tagging `v1.1.0` as the first stable on-water build.

---

## Branch model

```
main  ←── stable, always installable on the real iPad
  │
  └── dev  ←── active development (daily work, experiments)
        │
        └── feature/<name>  ←── isolated experiments (branch from dev)
```

### `main`
- Always reflects a **tested, installable build**.
- Only receives code via a **PR or merge from `dev`** — never direct commits of unproven features.
- Every significant stable build is **tagged** (`v<major>.<minor>.<patch>`).
- The iPad on the boat runs whatever tag was last archived from `main`.

### `dev`
- Day-to-day working branch. All agent sessions default here.
- May be ahead of `main` by many commits — that is expected.
- When a feature is validated on the water (or in the simulator to satisfaction), open a PR `dev → main`, merge, then tag.

### `feature/<name>`
- Created off `dev` for experiments that could destabilise the cockpit layout while in progress (e.g. `feature/nautical-charts` will rewrite `MapView` from SwiftUI `Map` to `UIViewRepresentable`).
- Kept isolated until the experiment is proven, then merged back into `dev`.
- Deleted after merge.

---

## Version numbering

Format: **`MAJOR.MINOR.PATCH`** (marketing) + monotonically increasing **build number**.

| Segment | Bump when… |
|---------|-----------|
| `MAJOR` | Incompatible data model change, or complete UI paradigm shift |
| `MINOR` | Meaningful new features added (instrument panels, chart overlays, advisor logic) |
| `PATCH` | Bug fixes, layout tweaks, copy changes — no new features |

Build number (`CURRENT_PROJECT_VERSION`) increments with every archive regardless of version.

### Tag format

```
v1.1.0   ← annotated tag on main, created at merge time
```

Create with:
```bash
git tag -a v1.1.0 -m "Short description of milestone"
git push origin v1.1.0
```

### Version history

| Tag | Date | Highlights |
|-----|------|-----------|
| `v1.0` (untagged) | 2026-03 | Initial working build — NMEA parsing, instruments, map |
| `v1.1.0` | 2026-05-11 | Downwind path advisor (iPad + iPhone), iPhone waypoint redesign, iPad landscape lock, 3-column metrics, direct bearing in advisor, multi-day formatting |

---

## Workflow: feature → stable

```
1. git checkout dev
2. git checkout -b feature/nautical-charts

   ... work in feature branch ...

3. git checkout dev && git merge feature/nautical-charts
4. Test on simulator (and ideally device)

5. git checkout main && git merge dev
6. git tag -a v1.2.0 -m "Nautical chart tile overlay (OpenSeaMap)"
7. git push && git push origin v1.2.0

8. Archive in Xcode → install on iPad
9. git checkout dev   ← back to work
```

---

## Planned next experiments (queue for `dev`/`feature/*`)

| Priority | Feature | Branch strategy |
|----------|---------|----------------|
| High | OpenSeaMap tile overlay | `feature/nautical-charts` — requires `MKMapView` migration |
| Medium | Polar-based VMG coaching (live deviation from target TWA) | `dev` directly — additive only |
| Medium | Watch complication refresh rate | `dev` directly |
| Low | S-57 / ENC vector chart overlay | `feature/enc-charts` — large, after nautical-charts lands |

---

## Agent session checklist

Before starting a new session on `dev`:
```bash
git status          # confirm you're on dev and clean
git pull            # pull any remote changes
agentos init .      # optional: refresh Agent OS index
```

Before ending a session that touched `dev`:
```bash
git add -A && git commit -m "..."
git push
agentos handoff update   # refresh current-handoff.md for next session
```
