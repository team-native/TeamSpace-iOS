import CoreGraphics

/// 간격 토큰. 사용: `.padding(Spacing.md)`
enum Spacing {
    static let hairline: CGFloat = 1
    static let xxxs: CGFloat = 2
    /// 제목과 부제 사이처럼 아주 촘촘한 간격
    static let compact: CGFloat = 3
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    /// 화면 좌우 기본 여백
    static let screen: CGFloat = 20
    /// 카드 내부 기본 여백
    static let card: CGFloat = 18
    /// 하단 플로팅 탭바에 가리지 않도록 두는 여백
    static let tabBarInset: CGFloat = 110
}
