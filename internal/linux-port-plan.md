# MDReader Linux port — plan

Linux companion to the macOS SwiftUI app, sharing the same repo, the same `markdown.css`, and as much rendering parity as possible. Built with **Qt 6 + QtWebEngine** in **Python** (PySide6).

**Toolkit decision:** Qt was chosen over GTK4+libadwaita because Hassan uses both GNOME and KDE and wants the app to feel native on both. KDE Plasma is built on Qt, so PySide6 apps are natively styled there; on GNOME they pick up an Adwaita-ish look via the GNOME Qt platform theme. GTK4+libadwaita would have been the better pick for GNOME-only but looks foreign on KDE.

## Goals (v1 feature parity with macOS)

- Open `.md`, `.markdown`, `.mdown`, `.mkd` files from file managers / CLI / drag-drop
- Render with the **same** GitHub-style theme (`markdown.css` reused verbatim)
- Font size 10–32px, 2px steps, default 16 — matches `DocumentViewModel.swift:11-23`
- Appearance: **System / Light / Dark** override — matches `DocumentViewModel.swift:4-8`
- RTL detection from first letter of first non-empty line in U+0590–U+08FF range — matches `DocumentView.swift:28-39`
- Print via `window.print()` in QtWebEngine (same approach as macOS, `MarkdownWebView.swift:43-46`)
- File associations (MIME `text/markdown`)
- Drag-and-drop a file onto the window to open it as a new tab
- **Tabs**: multiple files in one window via `QTabWidget`
- **Single-instance**: opening a `.md` file from the file manager while MDReader is already running adds a new tab to the existing window (no second process)
- Keyboard shortcuts: `Ctrl+O` open, `Ctrl+=`/`Ctrl+-` zoom, `Ctrl+0` reset, `Ctrl+P` print, `Ctrl+W` close tab, `Ctrl+Tab`/`Ctrl+Shift+Tab` switch tabs, `Ctrl+Q` quit
- Toolbar with theme picker and zoom controls (mirrors `ThemePickerView`)

## Non-goals (v1)

- Editing — read-only, same as macOS
- Relative-path image rendering — macOS uses `loadHTMLString(html, baseURL: nil)` (`MarkdownWebView.swift:23`), so neither side resolves relative images today. Parity = same limitation.
- Notarization / signing equivalents — Linux has no equivalent; Flatpak sandboxing covers the analogous trust story.
- A second top-level window — single-instance design means everything goes through tabs in the one window. (Drag-out-to-new-window is a v1.1 nice-to-have.)

## Why Qt 6 + QtWebEngine + Python (PySide6)

- **Cross-DE native feel**: Qt is the toolkit KDE Plasma is built on, so the app looks native on KDE out of the box. On GNOME it picks up an Adwaita-style theme via `qgnomeplatform`/`adwaita-qt`. GTK4+libadwaita would look great on GNOME but foreign on KDE.
- **`markdown.css` is reused unchanged** — single source of truth for the theme. The toolkit choice doesn't touch the renderer.
- **`cmark-gfm`** is already the macOS parser (`MarkdownRenderer.swift:1-37`). We use the `cmarkgfm` Python binding (same C library, same extensions: `table`, `strikethrough`, `autolink`, `tasklist`) → byte-identical HTML output.
- **`QTabWidget`** gives us tabs natively without needing libadwaita or AdwTabView.
- **`QtWebEngine`** is a Chromium-based widget. Slightly heavier than WebKitGTK (~30 MB more in bundles) but extremely well-tested and renders our HTML+CSS identically across distros.
- **PySide6** is the official Qt binding for Python. Cleaner API than PyGObject, type stubs are good, iteration is fast.
- **`xdg-desktop-portal`** handles file pickers, MIME associations, and notifications inside Flatpak regardless of toolkit, so file-chooser dialogs look native on whichever DE the user runs.

## Repo layout (single repo, sibling folder)

```
MDReader/                              # macOS Swift app — unchanged
MDReader-linux/                        # NEW
├── pyproject.toml                     # build/install (hatchling)
├── src/mdreader_linux/
│   ├── __init__.py
│   ├── __main__.py                    # python -m mdreader_linux entry point
│   ├── application.py                 # QApplication subclass, single-instance, file routing
│   ├── main_window.py                 # QMainWindow + QTabWidget + toolbar
│   ├── document_tab.py                # QWebEngineView wrapper (one per tab)
│   ├── renderer.py                    # cmark-gfm wrapper (port of MarkdownRenderer.swift)
│   ├── document.py                    # File loading, encoding (port of MarkdownDocument)
│   ├── view_state.py                  # font_size + appearance_mode (port of DocumentViewModel)
│   ├── rtl.py                         # RTL detection (port of String.isRTL)
│   ├── html_template.py               # buildFullHTML equivalent
│   └── ipc.py                         # Single-instance via QLocalServer/QLocalSocket
├── data/
│   ├── markdown.css                   # SYMLINK → ../../MDReader/Resources/markdown.css
│   ├── com.alsheikhmedia.MDReader.desktop
│   ├── com.alsheikhmedia.MDReader.metainfo.xml    # AppStream metadata
│   └── icons/
│       ├── scalable/apps/com.alsheikhmedia.MDReader.svg
│       └── symbolic/apps/com.alsheikhmedia.MDReader-symbolic.svg
├── packaging/
│   ├── flatpak/com.alsheikhmedia.MDReader.yaml
│   ├── flatpak/python3-cmarkgfm.json  # generated pip dep manifest
│   ├── rpm/mdreader.spec              # Fedora spec
│   └── appimage/AppImageBuilder.yml
├── tests/
│   ├── test_renderer.py               # parity tests vs. fixture HTML
│   ├── test_rtl.py
│   ├── test_view_state.py
│   └── fixtures/
│       ├── input.md
│       └── expected.html              # generated once from cmark-gfm CLI for regression
└── scripts/
    ├── run-dev.sh                     # python -m mdreader_linux
    └── build-flatpak.sh
```

The CSS symlink keeps both apps visually locked together. Only one file to edit when the theme changes. Packaging steps that can't follow symlinks (e.g. some RPM workflows) will copy it during install.

## Module mapping (Swift → Python)

| macOS file | Linux file | Notes |
|---|---|---|
| `MDReaderApp.swift` | `application.py` + `ipc.py` | `QApplication` subclass; on startup, try to connect to a `QLocalServer` named `com.alsheikhmedia.MDReader`. If it exists, send the file paths over the socket and exit (single-instance). Otherwise become the server. |
| `Models/MarkdownDocument.swift` | `document.py` | UTF-8 decode with `errors='replace'` fallback; expose `.text` and `.path`. |
| `ViewModels/DocumentViewModel.swift` | `view_state.py` | Plain dataclass with `Signal` for change notifications (one per tab). Same 10/32/16 bounds. |
| `Utilities/MarkdownRenderer.swift` | `renderer.py` | `cmarkgfm.markdown_to_html_with_extensions(md, extensions=['table','strikethrough','autolink','tasklist'])`. |
| `Views/MarkdownWebView.swift` | `document_tab.py` + `html_template.py` | `QWebEngineView` inside a `QWidget`; same HTML wrapper, font size injected via `--font-size` CSS variable, theme via body class — identical to macOS. |
| `Views/DocumentView.swift` (per-doc state + RTL) | `document_tab.py` + `rtl.py` | Each tab owns its own `view_state` and `document`. Direct port of the U+0590–U+08FF check. |
| `Views/ThemePickerView.swift` | `main_window.py` (toolbar) | `QToolBar` with `QActionGroup` for the three exclusive theme actions (System/Light/Dark) + zoom `QAction`s. |
| (no Swift equivalent) | `main_window.py` | `QMainWindow` containing a `QTabWidget` — closeable tabs, drag to reorder, middle-click to close. |

## Dependencies

### Runtime (Fedora packages)
- `python3` (≥ 3.11)
- `python3-pyside6` (Fedora packages this — confirm exact name on Fedora 43)
- `python3-pyside6-webengine` (or `python3-pyside6-addons`, depending on Fedora's packaging split)
- `qt6-qtwebengine`
- `python3-cmarkgfm` — if not packaged for Fedora, vendor via pip in venv / Flatpak module
- For native GNOME look on Plasma-less GNOME systems: `qgnomeplatform-qt6` (recommendation, not hard dep)
- For native KDE look: nothing — Qt picks up Plasma's Breeze theme automatically

### Dev
- `pytest`
- `flatpak-builder`
- `appstream-util` (validates the metainfo file)
- `desktop-file-validate`
- `appimage-builder` (Phase 4 only)

## Implementation phases

**Phase 1 — minimum walking skeleton** (target: a window that opens a file from the CLI and renders it)
- `pyproject.toml` + `__main__.py` + `application.py` + `main_window.py` + `document_tab.py` + `renderer.py` + `html_template.py`
- Symlink `markdown.css`
- `python -m mdreader_linux path/to/file.md` opens a window with one tab and renders
- No theme switching, no zoom, no tab UI yet — just prove the pipeline

**Phase 2 — feature parity**
- Toolbar with theme picker (System/Light/Dark `QActionGroup`) and zoom +/−/reset
- Keyboard shortcuts via `QShortcut` / `QAction.setShortcut`
- RTL detection
- Print via `page().runJavaScript("window.print()")`
- Drag-drop using `dragEnterEvent` / `dropEvent` on the main window (each dropped file → new tab)
- Tabs: `QTabWidget` wired up — closeable, reorderable, middle-click to close, `Ctrl+Tab` to cycle

**Phase 3 — desktop integration**
- `.desktop` file with `MimeType=text/markdown;text/x-markdown;` and `StartupWMClass=com.alsheikhmedia.MDReader`
- AppStream metainfo (validates with `appstream-util`)
- Icon (reuse the macOS app icon, export SVG)
- **Single-instance** via `QLocalServer` listening on a socket named `com.alsheikhmedia.MDReader`. Second launch tries `QLocalSocket.connectToServer()`; on success, sends file paths and exits. On failure, becomes the server and runs the GUI.
- Install paths follow XDG: `/usr/share/applications/`, `/usr/share/icons/hicolor/`, `/usr/share/metainfo/`

**Phase 4 — packaging**
- **Flatpak first** (broadest reach, sandboxed, easiest to test)
  - Manifest based on `org.kde.Platform//6.7` (Qt 6 runtime)
  - Bundle `cmarkgfm` and PySide6 as pip modules (or use the runtime's PySide6 if available)
  - Permissions: `--filesystem=host:ro` (read-only access to user files), `--socket=wayland --socket=fallback-x11`
  - Verify with `flatpak run` locally before publishing
- **RPM** (Fedora-native)
  - Spec file targeting Fedora 41/42/43
  - BuildRequires: `python3-devel`, `python3-hatchling`
  - Requires: `python3-pyside6`, `qt6-qtwebengine`, `python3-cmarkgfm`
  - Build via `rpmbuild` or `mock`; publish via COPR
- **AppImage** (last — biggest bundle)
  - `appimage-builder` recipe bundling Python, Qt 6, QtWebEngine, PySide6, all deps
  - Test on a clean older distro (e.g., Ubuntu 22.04 LTS) to verify portability
  - Size budget: ~150–200 MB (Qt + QtWebEngine are heavy; this is unavoidable)

**Phase 5 — tests + CI**
- `pytest` for renderer / RTL / view_state / document loading
- HTML parity fixture: same input markdown rendered by both Swift `MarkdownRenderer` and Python `renderer.py` → diff should be empty (or whitespace-only). Generate the macOS-side fixture once via a CLI helper and check it in.
- GitHub Actions Linux job: `pytest`, `desktop-file-validate`, `appstream-util validate`, `flatpak-builder --install-deps-from=flathub`
- Existing macOS workflow unchanged
- The Codeberg mirror picks up the new folder for free

## Distribution rollout order

1. Local install via `pip install -e .` + manual `.desktop` install for dogfooding on Fedora
2. Flatpak (private/local first, then submit to Flathub once stable)
3. RPM via COPR repo
4. AppImage for users on non-Fedora distros without Flatpak
5. Update README with Linux install instructions; clarify Homebrew cask is macOS-only

## Resolved decisions

| Question | Decision |
|---|---|
| Markdown parser | `cmarkgfm` (Python binding to the same C library macOS uses) for byte-identical HTML output |
| App ID (both platforms) | `com.alsheikhmedia.MDReader` — Hassan owns `alsheikhmedia.com`. macOS migrated from `com.hassanalsheikh.MDReader` in this same change. |
| Version bump | 3.2.0 — Linux is additive, no breaking changes for macOS users |
| Tab persistence | Yes — save open file paths on quit, restore on launch, silently skip files that no longer exist or aren't readable. Files passed on the command line are opened *in addition to* the restored session. |
| Single-instance | Yes — second-launched files become new tabs in the running window |
| Tabs vs. window-per-file | **Tabs** (`QTabWidget`) from v1 |
| Versioning | Shared — both apps bump together, single changelog |
| README | One top-level README with a Linux section |
| Toolkit | **Qt 6 + PySide6 + QtWebEngine** (KDE-native, GNOME-acceptable) |

## Tab persistence — design notes

State file at `$XDG_CONFIG_HOME/MDReader/state.json` (resolved via `QStandardPaths.AppConfigLocation`). On graceful quit, write:

```json
{
  "version": 1,
  "open_files": ["/abs/path/one.md", "/abs/path/two.md"],
  "active_index": 1
}
```

On launch:
1. Read state file (silently empty if missing or malformed)
2. Filter `open_files` to entries that still exist and are readable — drop the rest without warning
3. Open each remaining file as a tab; restore the active index if still valid (else default to 0)
4. If the launch arguments include file paths, open those *additionally* and make the last one the active tab
5. If after all of the above we have zero tabs, show an empty welcome state (or a "File → Open…" prompt)

Use atomic writes (`tempfile` + `os.replace`) to avoid corrupting the state file on crash.

## macOS bundle ID migration (done as part of this plan)

Migrated from `com.hassanalsheikh.MDReader` → `com.alsheikhmedia.MDReader`:
- `project.yml` — `bundleIdPrefix` and explicit `PRODUCT_BUNDLE_IDENTIFIER`
- `MDReader.xcodeproj/project.pbxproj` — both Debug and Release configs

Hassan is the only user, so the user-facing migration cost is zero. Build verification still needs to happen on the Mac (Fedora box can't run `xcodegen`/`xcodebuild`):
- `xcodegen generate` (regenerate .xcodeproj from project.yml — should be a no-op since both were edited in lockstep)
- `xcodebuild -scheme MDReader -configuration Release build`
- Run the resulting `.app` once and verify it opens a `.md` file

## Next step

Phase 1: scaffold `MDReader-linux/` at the repo root and get a window opening on the Fedora box.
