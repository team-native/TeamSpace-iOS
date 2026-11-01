import SwiftUI

/// Figma `notice` / `안내` — 아이콘 + 안내 문구
/// - primary: 연한 파란 배경 + 파란 글씨 (01 로그인 · 계정 요청)
/// - muted: 회색 배경 + ink2 글씨 (02 알림 권한 · 설정)
struct InfoBanner: View {
    enum Style {
        case primary
        case muted
    }

    let message: String
    var icon: TSIcon = .info
    var style: Style = .primary

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            icon.sized(style == .primary ? .md : .base, weight: .semibold)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
            Text(message)
                .tsFont(style == .primary ? .footnote : .caption)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(style == .primary ? Spacing.lg : Spacing.md + Spacing.xxxs)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }

    private var iconColor: Color {
        style == .primary ? .tsPrimary : .tsInk3
    }

    private var textColor: Color {
        style == .primary ? .tsPrimary : .tsInk2
    }

    private var background: Color {
        style == .primary ? .tsPrimarySoft : .tsSurface2
    }
}

#Preview {
    VStack {
        InfoBanner(message: "요청 정보는 운영진(NativeOps)만 확인해요. 승인되면 메일과 알림으로 알려드려요.", icon: .shield)
        InfoBanner(message: "알림 권한은 언제든 기기 설정에서 바꿀 수 있어요.", icon: .infoCircle, style: .muted)
    }
    .padding()
}
