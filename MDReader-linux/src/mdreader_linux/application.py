"""QApplication subclass and main() entry point.

Phase 1 scope: parse argv for a single file path, open one window with one
document. No file picker, no single-instance, no settings — those land in
later phases.
"""

import sys
from pathlib import Path

from PySide6.QtWidgets import QApplication

from .document import Document
from .main_window import MainWindow

APP_ID = "com.alsheikhmedia.MDReader"


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv if argv is None else argv)

    if len(argv) < 2:
        print(
            "Usage: python -m mdreader_linux <file.md>",
            file=sys.stderr,
        )
        return 2

    path = Path(argv[1]).expanduser()
    if not path.exists():
        print(f"error: file not found: {path}", file=sys.stderr)
        return 1
    if not path.is_file():
        print(f"error: not a regular file: {path}", file=sys.stderr)
        return 1

    app = QApplication(argv)
    app.setApplicationName("MDReader")
    app.setApplicationDisplayName("MDReader")
    app.setOrganizationDomain("alsheikhmedia.com")
    # Tells Wayland compositors which .desktop file the window belongs to
    # (for icon, app name, etc). Harmless before Phase 3 installs the file.
    app.setDesktopFileName(APP_ID)

    document = Document.load(path)
    window = MainWindow(document)
    window.show()

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
