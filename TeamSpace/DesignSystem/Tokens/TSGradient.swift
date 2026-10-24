import SwiftUI

/// Figma 에서 쓰인 그라디언트 토큰
enum TSGradient {
    static let logo = LinearGradient(
        colors: [Color.tsLogoStart, Color.tsLogoEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
