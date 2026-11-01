import SwiftUI

/// Figma 화면 상단 큰 제목 + 설명 (22 Bold / 13 ink2)
struct ScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScreenTitle(title: "어떤 알림을 받을까요?", subtitle: "필요한 알림만 골라 받을 수 있어요.")
        .padding()
}
