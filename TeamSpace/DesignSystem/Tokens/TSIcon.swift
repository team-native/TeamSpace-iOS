import SwiftUI

/// Figma 아이콘 → SF Symbols 매핑 (탭바 아이콘은 Figma 원본 SVG)
enum TSIcon: String {
    case mail = "envelope"
    case eye = "eye"
    case eyeSlash = "eye.slash"
    case check = "checkmark"
    case info = "exclamationmark.circle"
    case chevronLeft = "chevron.left"
    case chevronDown = "chevron.down"
    case shield = "checkmark.shield"
    case clock = "clock"
    // 하단 탭바 — Figma 원본 SVG (Resources/Assets.xcassets/Icons)
    case tabHome = "tab-home"
    case tabFinance = "tab-finance"
    case tabApproval = "tab-approval"
    case tabDocuments = "tab-documents"
    case tabWorkspace = "tab-workspace"

    /// Figma 에서 가져온 SVG 에셋 아이콘
    private static let assetIcons: Set<TSIcon> = [.tabHome, .tabFinance, .tabApproval, .tabDocuments, .tabWorkspace]

    var image: Image {
        if Self.assetIcons.contains(self) {
            return Image(rawValue).renderingMode(.template)
        }
        return Image(systemName: rawValue)
    }
}
