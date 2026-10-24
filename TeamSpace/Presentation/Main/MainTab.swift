import Foundation

/// 하단 탭 (Figma 04-1 TabBar)
enum MainTab: String, CaseIterable, Identifiable {
    case home
    case finance
    case approval
    case documents
    case workspace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "홈"
        case .finance: return "재무"
        case .approval: return "결재"
        case .documents: return "문서함"
        case .workspace: return "내 공간"
        }
    }

    var icon: TSIcon {
        switch self {
        case .home: return .tabHome
        case .finance: return .tabFinance
        case .approval: return .tabApproval
        case .documents: return .tabDocuments
        case .workspace: return .tabWorkspace
        }
    }

    var tabBarItem: TSTabBarItem {
        TSTabBarItem(id: rawValue, title: title, icon: icon)
    }
}
