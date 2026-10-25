import SwiftUI

/// Figma 진행률 막대 (6pt, r3)
struct TSProgressBar: View {
    /// 0~100
    let percent: Int
    var tint: Color = .tsPrimary

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.tsSurface2)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
                }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("진행률")
        .accessibilityValue("\(percent)%")
    }
}

#Preview {
    TSProgressBar(percent: 35).padding()
}
