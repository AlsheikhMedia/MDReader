"""Markdown -> HTML rendering via cmark-gfm.

Mirrors MDReader/Utilities/MarkdownRenderer.swift on the macOS side. Both
sides use the same C library (cmark-gfm) with the same extensions enabled,
so the HTML output should be byte-identical for any given input — except
for one small post-process described below.
"""

import re

import cmarkgfm
from cmarkgfm.cmark import Options as CmarkOptions

# Same extension set as the Swift side: see MarkdownRenderer.swift:13
GFM_EXTENSIONS = ("table", "strikethrough", "autolink", "tasklist")

# CMARK_OPT_DEFAULT (0) | CMARK_OPT_UNSAFE — matches MarkdownRenderer.swift:9
_OPTIONS = CmarkOptions.CMARK_OPT_UNSAFE

# cmarkgfm 2025.10.22 emits task-list checkboxes without the `task-list-item`
# class that the GitHub HTML spec calls for. markdown.css:144 styles
# `.task-list-item` to hide bullets, so without this fix-up Linux would show
# a bullet next to every checkbox while macOS doesn't. The regex matches the
# exact shape cmarkgfm produces (`<li><input type="checkbox" ... />`) and
# inserts the class on the <li>.
_TASK_LIST_LI_RE = re.compile(r'<li>(<input type="checkbox"[^>]*/>)')


def render_html(markdown_text: str) -> str:
    """Render markdown text to HTML, matching the macOS app's output."""
    html = cmarkgfm.markdown_to_html_with_extensions(
        markdown_text,
        options=_OPTIONS,
        extensions=list(GFM_EXTENSIONS),
    )
    return _TASK_LIST_LI_RE.sub(r'<li class="task-list-item">\1', html)
