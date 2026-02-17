import Foundation
import cmark_gfm
import cmark_gfm_extensions

enum MarkdownRenderer {
    static func renderHTML(from markdown: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        let options = CMARK_OPT_DEFAULT | CMARK_OPT_UNSAFE
        let parser = cmark_parser_new(options)
        defer { cmark_parser_free(parser) }

        let extensionNames = ["table", "strikethrough", "autolink", "tasklist"]
        for name in extensionNames {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        markdown.withCString { str in
            cmark_parser_feed(parser, str, strlen(str))
        }

        guard let document = cmark_parser_finish(parser) else {
            return "<p>Failed to parse markdown</p>"
        }
        defer { cmark_node_free(document) }

        let extensions = cmark_parser_get_syntax_extensions(parser)
        guard let htmlCString = cmark_render_html(document, options, extensions) else {
            return "<p>Failed to render HTML</p>"
        }
        defer { free(htmlCString) }

        return String(cString: htmlCString)
    }
}
