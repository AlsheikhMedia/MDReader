import SwiftUI

struct DocumentView: View {
    let document: MarkdownDocument
    @StateObject private var viewModel = DocumentViewModel()
    @State private var printTrigger = false

    var body: some View {
        MarkdownWebView(
            markdown: document.text,
            fontSize: viewModel.fontSize,
            appearanceMode: viewModel.appearanceMode,
            isRTL: document.text.isRTL,
            printTrigger: $printTrigger
        )
        .frame(minWidth: 300, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ThemePickerView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(viewModel.colorSchemeOverride)
        .keyboardShortcut(commands: viewModel)
        .keyboardShortcut("p", modifiers: .command) { printTrigger = true }
    }
}

private extension String {
    var isRTL: Bool {
        guard let firstLine = components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return false
        }
        let stripped = firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = stripped.unicodeScalars.first(where: { CharacterSet.letters.contains($0) }) else {
            return false
        }
        return CharacterSet(charactersIn: "\u{0590}"..."\u{08FF}").contains(first)
    }
}

private struct KeyboardShortcutsModifier: ViewModifier {
    @ObservedObject var viewModel: DocumentViewModel

    func body(content: Content) -> some View {
        content
            .keyboardShortcut("+", modifiers: .command) { viewModel.increaseFontSize() }
            .keyboardShortcut("=", modifiers: .command) { viewModel.increaseFontSize() }
            .keyboardShortcut("-", modifiers: .command) { viewModel.decreaseFontSize() }
            .keyboardShortcut("0", modifiers: .command) { viewModel.resetFontSize() }
    }
}

private extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.background(
            Button("") { action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .hidden()
        )
    }

    func keyboardShortcut(commands viewModel: DocumentViewModel) -> some View {
        modifier(KeyboardShortcutsModifier(viewModel: viewModel))
    }
}
