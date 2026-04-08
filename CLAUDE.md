# MDReader

A read-only markdown viewer for macOS, built with SwiftUI.

## Build Commands

```bash
# Generate Xcode project (requires xcodegen)
xcodegen generate

# Build from command line
xcodebuild -scheme MDReader -configuration Release build

# Create DMG (after release build)
# 1. Copy .app from build/Build/Products/Release/ into staging dir with /Applications symlink
# 2. hdiutil create -volname "MDReader" -srcfolder <staging> -ov -format UDZO ~/Downloads/MDReader.dmg
```

## Architecture

- **SwiftUI** with DocumentGroup-based file handling
- **FileDocument** conformance for markdown files
- **ObservableObject** for view model state (font size, theme mode)
- **swift-markdown-ui** package for rendering
- Native macOS menu bar and keyboard shortcuts

## Project Structure

```
MDReader/
├── App/
│   └── MDReaderApp.swift             # Entry point, DocumentGroup, About panel
├── Models/
│   └── MarkdownDocument.swift        # FileDocument conformance, UTType for .md
├── ViewModels/
│   └── DocumentViewModel.swift       # Font size (10–32), appearance mode
├── Views/
│   ├── DocumentView.swift            # Scrollable markdown + toolbar + print
│   └── ThemePickerView.swift         # Appearance mode + font size controls
├── Theme/
│   └── MarkdownTheme+Custom.swift    # GitHub-style theme with configurable font
├── Resources/
└── Info.plist                        # File associations, UTType declarations
```

## Key Patterns

- Read-only viewer (not an editor)
- File associations for .md, .markdown, .mdown, .mkd
- macOS 14.0+ deployment target
- Keyboard shortcuts: Cmd+O (open), Cmd+/- (zoom), Cmd+0 (reset), Cmd+P (print)
- DocumentGroup handles file open from Finder natively
- Custom UTType: `net.daringfireball.markdown`

## Distribution

- **GitHub repo (primary)**: https://github.com/AlsheikhMedia/MDReader
- **Codeberg mirror (read-only)**: https://codeberg.org/AlsheikhMedia/MDReader — auto-synced from GitHub via `.github/workflows/mirror-to-codeberg.yml`
- **Homebrew tap**: https://github.com/HassanAlsheikh/homebrew-tap (`brew tap HassanAlsheikh/tap && brew install --cask mdreader`)
- **GitHub Releases**: DMG attached to releases
- **Not notarized** — users need `xattr -cr /Applications/MDReader.app` or right-click > Open
