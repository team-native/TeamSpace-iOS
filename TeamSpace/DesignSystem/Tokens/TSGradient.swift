import SwiftUI

/// Figma 에서 쓰인 그라디언트 토큰
enum TSGradient {
    static let logo = LinearGradient(
        colors: [Color.tsLogoStart, Color.tsLogoEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 02-6 알림 미리보기 카드
    static let notificationPreview = LinearGradient(
        colors: [Color.tsPreviewStart, Color.tsPreviewEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
