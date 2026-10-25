import SwiftUI
import UIKit

/// Figma `TS2 Color` 변수 컬렉션(Light / Dark)을 그대로 옮긴 색상 토큰.
/// 화면에서는 반드시 `Color.ts~` 만 사용하고 hex 값을 직접 쓰지 않습니다.
extension Color {
    // MARK: Surface
    static let tsBackground = Color(light: 0xF6F7F9, dark: 0x0E0F12)
    static let tsSurface = Color(light: 0xFFFFFF, dark: 0x17181C)
    static let tsSurface2 = Color(light: 0xF2F4F6, dark: 0x202227)
    static let tsLine = Color(light: 0xE5E8EB, dark: 0x2A2C32)
    static let tsScrim = Color(light: 0x16171A, dark: 0x000000)

    // MARK: Text
    static let tsInk = Color(light: 0x191F28, dark: 0xF2F1EE)
    static let tsInk2 = Color(light: 0x4E5968, dark: 0xB7B9C1)
    static let tsInk3 = Color(light: 0x8B95A1, dark: 0x868991)
    static let tsOnPrimary = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
    static let tsOnInk = Color(light: 0xFFFFFF, dark: 0x16171A)

    // MARK: Brand / Semantic (Figma: honey · info)
    static let tsPrimary = Color(light: 0x3182F6, dark: 0x4C94FF)
    static let tsPrimarySoft = Color(light: 0xF1F6FE, dark: 0x202227)
    static let tsPositive = Color(light: 0x2E9A69, dark: 0x4CC38A)
    static let tsPositiveSoft = Color(light: 0xE7F5EE, dark: 0x15291F)
    static let tsNegative = Color(light: 0xD65A4E, dark: 0xF07A6E)
    static let tsNegativeSoft = Color(light: 0xFCEDEA, dark: 0x2E1A18)
    static let tsViolet = Color(light: 0x8B80E9, dark: 0x9B85FF)
    static let tsVioletSoft = Color(light: 0xF5F3FD, dark: 0x231D3A)
    static let tsApricot = Color(light: 0xE9A07A, dark: 0xFF9F5C)
    static let tsApricotSoft = Color(light: 0xFDF5F0, dark: 0x2E2119)
    static let tsAmber = Color(light: 0xE88C00, dark: 0xF4C15A)
    static let tsAmberSoft = Color(light: 0xFFF4E0, dark: 0x2B2416)
    static let tsHoney = Color(light: 0xFEDB6B, dark: 0xF4C15A)

    // MARK: 06-3 템플릿 상세
    static let tsTemplateAccent = Color(light: 0x4C71F5, dark: 0x8EA5FF)
    static let tsTemplateButton = Color(light: 0x4C71F5, dark: 0x4C71F5)
    static let tsTemplateSoft = Color(light: 0xEEF2FE, dark: 0x222A45)
    static let tsTemplateBanner = Color(light: 0xF0F3FF, dark: 0x222A45)
    static let tsTemplateSecondary = Color(light: 0x6B7684, dark: 0xB7B9C1)

    // MARK: Brand logo (Figma 로고 캡슐)
    static let tsLogoStart = Color(light: 0xFFE17E, dark: 0xFFE17E)
    static let tsLogoEnd = Color(light: 0xFFD34E, dark: 0xFFD34E)

    // MARK: 알림 미리보기 카드 그라디언트 (02-6)
    static let tsPreviewStart = Color(light: 0xDDEBFF, dark: 0x1D2A3D)
    static let tsPreviewEnd = Color(light: 0xFFF8D7, dark: 0x2B2716)

    // MARK: 강조 카드 그라디언트 (04-1 사용 가능 금액)
    static let tsPrimaryDeep = Color(light: 0x1A6FE8, dark: 0x1A5FCC)
    static let tsPrimaryLight = Color(light: 0x56A1FF, dark: 0x3F86F0)

    // MARK: Avatar placeholder
    static let tsAvatarStart = Color(light: 0xE2E2E2, dark: 0x2A2C32)
    static let tsAvatarEnd = Color(light: 0xF1F1F1, dark: 0x202227)
}

extension Color {
    /// 라이트/다크 모드에 따라 바뀌는 색상
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
