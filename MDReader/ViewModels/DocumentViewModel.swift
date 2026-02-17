import SwiftUI

final class DocumentViewModel: ObservableObject {
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }

    @Published var appearanceMode: AppearanceMode = .system
    static let defaultFontSize: CGFloat = 16
    @Published var fontSize: CGFloat = DocumentViewModel.defaultFontSize

    func increaseFontSize() {
        fontSize = min(fontSize + 2, 32)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, 10)
    }

    func resetFontSize() {
        fontSize = Self.defaultFontSize
    }

    var colorSchemeOverride: ColorScheme? {
        switch appearanceMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
