# Agent OS output (this repository)

The tooling stores generated files under **`.agent-os/`**. **Finder** and **Terminal** can always see them; **Xcode** needs two separate ideas (below).

## Xcode: why new files do not appear automatically

The **Project navigator** is not a full folder listing. It only shows files that are **members of the `.xcodeproj`** (listed in the project file). Creating **`AGENT_OS.md`** on disk does **not** add it to the project.

**One-time — add this file to the app project**

1. In Xcode: **File → Add Files to "…"** (pick your `.xcodeproj` target), or right-click a group → **Add Files to …**.
2. Select **`AGENT_OS.md`** at the repository root. Turn **off** “Copy items if needed” if the file is already there. Choose **Create groups** (usual).
3. For generated Agent OS output: repeat **Add Files…** and pick the **`.agent-os`** folder (or individual files under it). Use a **folder reference** (blue folder) if you want the tree to track the directory on disk.

After that, **`AGENT_OS.md`** and **`.agent-os`** show in the sidebar like any other project file.

When you use the **`agentos`** CLI, it tries to **edit `project.pbxproj`** so **`AGENT_OS.md`**, **`AGENTS.md`** (only if that file already exists at the repo root), and a **`.agent-os` folder** (if present) appear in Xcode. It prefers **`<folderName>.xcodeproj`** at the repo root when that exists; otherwise it picks the shallowest ``*.xcodeproj``. Run **`agentos xcode integrate`** to run the same step manually or pass **`--xcodeproj`**. Set **`AGENT_OS_SKIP_XCODE_INTEGRATE=1`** to disable. Use **`agentos xcode integrate --no-agents`** to skip adding **`AGENTS.md`**.

## Open the real folder (without adding to the project)

- **Finder:** press **⌘⇧.** (Command–Shift–Period) to show hidden files, then open **`.agent-os`**.
- **Xcode:** **File → Open…** and open a file by path, e.g. `.agent-os/exports/context-pack.md`.

## Important paths (relative to repo root)

| What | Path |
|------|------|
| Cursor / team agent rules (optional) | **`AGENTS.md`** at repo root — read when present; CLI never edits it |
| Agent context (workflow, you edit) | `.agent-os/context/` — **`scanned-summary.md`** (auto), begin/end chat, rolling `cache.md`, memory, questions |
| Context pack (JSON, for tools) | `.agent-os/exports/context-pack.json` |
| Context pack (Markdown summary) | `.agent-os/exports/context-pack.md` |
| Working cache | `.agent-os/state/cache.md` |
| Handoff | `.agent-os/state/current-handoff.md` |
| Drift report | `.agent-os/state/drift-report.md` |
| Last scan summary | `.agent-os/logs/last-scan.json` |
| SQLite index | `.agent-os/data/agent_os.db` |

This file is rewritten when you run **`agentos`** commands (after **`agentos-scan`** has created `.agent-os`). Paths above are relative to **this file’s directory** (the repository root).
