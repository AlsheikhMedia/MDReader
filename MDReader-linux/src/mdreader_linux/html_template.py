"""Full HTML wrapper for the rendered markdown.

Mirrors buildFullHTML() in MDReader/Views/MarkdownWebView.swift so the
document looks identical inside QtWebEngine and WKWebView.
"""

from importlib import resources

from . import renderer


def _load_css() -> str:
    css_file = resources.files(__package__).joinpath("resources/markdown.css")
    return css_file.read_text(encoding="utf-8")


def build_full_html(
    markdown_text: str,
    *,
    font_size: float = 16.0,
    theme_class: str = "",
    direction: str = "ltr",
) -> str:
    """Build the full HTML document that gets handed to QtWebEngine.

    Phase 1 callers use only `markdown_text`. Phase 2 will pass `font_size`,
    `theme_class`, and `direction` to mirror the macOS toolbar controls.
    """
    rendered = renderer.render_html(markdown_text)
    css = _load_css()
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root {{ --font-size: {font_size}px; }}
{css}
</style>
</head>
<body class="{theme_class}" dir="{direction}">
<article class="markdown-body">
{rendered}
</article>
</body>
</html>
"""
