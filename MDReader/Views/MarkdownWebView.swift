import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let fontSize: CGFloat
    let appearanceMode: DocumentViewModel.AppearanceMode
    let isRTL: Bool
    @Binding var printTrigger: Bool

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let coordinator = context.coordinator

        if coordinator.previousMarkdown != markdown || coordinator.previousIsRTL != isRTL {
            let html = buildFullHTML()
            webView.loadHTMLString(html, baseURL: nil)
            coordinator.previousMarkdown = markdown
            coordinator.previousIsRTL = isRTL
            coordinator.previousFontSize = fontSize
            coordinator.previousAppearanceMode = appearanceMode
        } else {
            if coordinator.previousFontSize != fontSize {
                webView.evaluateJavaScript(
                    "document.documentElement.style.setProperty('--font-size', '\(fontSize)px')"
                )
                coordinator.previousFontSize = fontSize
            }
            if coordinator.previousAppearanceMode != appearanceMode {
                webView.evaluateJavaScript(
                    "document.body.className = '\(themeClassName)'"
                )
                coordinator.previousAppearanceMode = appearanceMode
            }
        }

        if printTrigger {
            DispatchQueue.main.async { printTrigger = false }
            webView.evaluateJavaScript("window.print()")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previousMarkdown: String?
        var previousFontSize: CGFloat?
        var previousAppearanceMode: DocumentViewModel.AppearanceMode?
        var previousIsRTL: Bool?
    }

    private var themeClassName: String {
        switch appearanceMode {
        case .system: ""
        case .light: "light-mode"
        case .dark: "dark-mode"
        }
    }

    private func buildFullHTML() -> String {
        let renderedHTML = MarkdownRenderer.renderHTML(from: markdown)
        let css = Self.loadCSS()
        let direction = isRTL ? "rtl" : "ltr"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root { --font-size: \(fontSize)px; }
        \(css)
        </style>
        </head>
        <body class="\(themeClassName)" dir="\(direction)">
        <article class="markdown-body">
        \(renderedHTML)
        </article>
        </body>
        </html>
        """
    }

    private static func loadCSS() -> String {
        guard let url = Bundle.main.url(forResource: "markdown", withExtension: "css"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return css
    }
}
