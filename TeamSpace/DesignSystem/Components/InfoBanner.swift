import SwiftUI

/// Figma `notice` / `안내` — 아이콘 + 안내 문구 (연한 파란 배경)
struct InfoBanner: View {
    let message: String
    var icon: TSIcon = .info

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            icon.image
                .tsIconSize(.md, weight: .semibold)
                .foregroundStyle(Color.tsPrimary)
                .accessibilityHidden(true)
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

#Preview {
    InfoBanner(message: "요청 정보는 운영진(NativeOps)만 확인해요. 승인되면 메일과 알림으로 알려드려요.", icon: .shield)
        .padding()
}
