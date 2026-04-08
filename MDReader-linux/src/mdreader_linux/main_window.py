"""Top-level application window.

In Phase 1 this is a QMainWindow with a single DocumentTab as its central
widget. In Phase 2 a QTabWidget gets inserted between the window and the
tabs to support multiple documents at once.
"""

from PySide6.QtWidgets import QMainWindow

from .document import Document
from .document_tab import DocumentTab


class MainWindow(QMainWindow):
    def __init__(self, document: Document) -> None:
        super().__init__()
        self.setWindowTitle(f"{document.path.name} — MDReader")
        self.resize(900, 700)
        # Matches DocumentView.swift:16 — frame(minWidth: 300, minHeight: 400)
        self.setMinimumSize(300, 400)

        self._tab = DocumentTab(document, parent=self)
        self.setCentralWidget(self._tab)
