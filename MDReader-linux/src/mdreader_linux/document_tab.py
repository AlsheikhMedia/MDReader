"""A single markdown document view.

In Phase 1 the main window holds exactly one of these as its central widget.
In Phase 2 the main window will hold a QTabWidget of these instead.

Mirrors MDReader/Views/MarkdownWebView.swift on the macOS side.
"""

from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtWidgets import QVBoxLayout, QWidget

from . import html_template
from .document import Document


class DocumentTab(QWidget):
    def __init__(self, document: Document, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self._document = document

        self._web_view = QWebEngineView(self)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self._web_view)

        # Phase 1: render with hard-coded defaults. Phase 2 will pass font
        # size, theme class, and direction from the view state.
        html = html_template.build_full_html(document.text)
        # No base URL — matches loadHTMLString(html, baseURL: nil) in
        # MarkdownWebView.swift:23. Means relative-path images don't resolve
        # on either platform; that's intentional parity for now.
        self._web_view.setHtml(html)

    @property
    def document(self) -> Document:
        return self._document
