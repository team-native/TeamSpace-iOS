import SwiftUI

/// Figma `_Components_ / LOGO` (logo-lockup) — 심볼(원본 SVG) + 브랜드명
struct BrandLogo: View {
    static let brandName = "Native"

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image("brand-logo-mark")
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 22)
            Text(Self.brandName)
                .tsFont(.logo)
                .foregroundStyle(Color.tsInk)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.brandName)
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        BrandLogo()
        BrandLogo().preferredColorScheme(.dark)
    }
    .padding()
}
