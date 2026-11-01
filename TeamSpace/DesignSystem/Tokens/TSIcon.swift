import SwiftUI

/// Figma 아이콘 → SF Symbols 매핑 (탭바 아이콘은 Figma 원본 SVG)
enum TSIcon: String {
    case mail = "envelope"
    case eye = "eye"
    case eyeSlash = "eye.slash"
    case check = "checkmark"
    case info = "exclamationmark.circle"
    case chevronLeft = "ic-chevron-left"
    case chevronDown = "chevron.down"
    case shield = "checkmark.shield"
    case clock = "clock"
    // 02 알림 — Figma 원본 SVG
    case clipboard = "ic-clipboard"
    case creditCard = "ic-credit-card"
    case calendar = "ic-calendar"
    case bookOpen = "ic-book-open"
    case bell = "ic-bell"
    case checkCircle = "ic-check-circle"
    case settings = "ic-settings"
    // 하단 탭바 — Figma 원본 SVG (Resources/Assets.xcassets/Icons)
    case tabHome = "tab-home"
    case tabFinance = "tab-finance"
    case tabApproval = "tab-approval"
    case tabDocuments = "tab-documents"
    case tabWorkspace = "tab-workspace"

    /// Figma 에서 가져온 SVG 에셋 아이콘
    private static let assetIcons: Set<TSIcon> = [
        .chevronLeft, .clipboard, .creditCard, .calendar, .bookOpen, .bell, .checkCircle, .settings,
        .tabHome, .tabFinance, .tabApproval, .tabDocuments, .tabWorkspace
    ]

    var image: Image {
        if Self.assetIcons.contains(self) {
            return Image(rawValue).renderingMode(.template)
        }
        return Image(systemName: rawValue)
    }

    /// 크기 토큰에 맞춰 그립니다. (SVG 에셋 · SF Symbol 모두 같은 방법으로 사용)
    @ViewBuilder
    func sized(_ size: TSIconSize, weight: Font.Weight = .regular) -> some View {
        if Self.assetIcons.contains(self) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: size.size, height: size.size)
        } else {
            image.tsIconSize(size, weight: weight)
        }
    }
}
