import SwiftUI

/// 07-14 화면 모드 — 기기에만 저장해요.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "app.appearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "시스템 설정"
        case .light: return "라이트"
        case .dark: return "다크"
        }
    }

    /// "시스템 설정을 따라가요"
    var detail: String {
        switch self {
        case .system: return "시스템 설정을 따라가요"
        case .light: return "항상 밝은 화면으로 보여요"
        case .dark: return "항상 어두운 화면으로 보여요"
        }
    }

    /// nil 이면 기기 설정을 따라가요.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
