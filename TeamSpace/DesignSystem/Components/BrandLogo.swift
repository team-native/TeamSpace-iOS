import SwiftUI

/// Figma `logo-lockup` — 노란 캡슐 심볼 + 브랜드명
struct BrandLogo: View {
    static let brandName = "Native"

    var body: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: -4) {
                Capsule()
                    .fill(TSGradient.logo)
                    .frame(width: 9, height: 20)
                    .rotationEffect(.degrees(35))
                Capsule()
                    .fill(TSGradient.logo)
                    .opacity(0.7)
                    .frame(width: 9, height: 20)
                    .rotationEffect(.degrees(35))
            }
            .frame(width: 23, height: 22)
            Text(Self.brandName)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.brandName)
    }
}

#Preview {
    BrandLogo().padding()
}
