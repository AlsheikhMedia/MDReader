"""Markdown document loading.

Mirrors MDReader/Models/MarkdownDocument.swift on the macOS side. macOS
fails on invalid UTF-8; we use errors='replace' instead because Linux
files come from a wider variety of sources and a partial render is more
useful than a hard error.
"""

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Document:
    path: Path
    text: str

    @classmethod
    def load(cls, path: str | Path) -> "Document":
        resolved = Path(path).expanduser().resolve()
        text = resolved.read_text(encoding="utf-8", errors="replace")
        return cls(path=resolved, text=text)
