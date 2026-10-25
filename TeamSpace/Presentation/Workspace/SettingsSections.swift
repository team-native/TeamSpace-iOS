import SwiftUI

/// 07-14 회색 소제목 + 흰 카드
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .tsFont(.caption2Bold)
                .foregroundStyle(Color.tsInk3)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, Spacing.lg)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

/// 07-14 설정 한 줄 — 제목 · 설명 · 오른쪽 값/배지 · 쉐브론
struct SettingsRow: View {
    let title: String
    var subtitle: String?
    var trailing: String?
    var badge: String?
    var showsChevron = true

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .tsFont(.bodyLarge)
                    .foregroundStyle(Color.tsInk)
                if let subtitle {
                    Text(subtitle)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            Spacer(minLength: Spacing.sm)
            if let badge {
                StatusBadge(title: badge, tone: .primary, size: .small)
            }
            if let trailing {
                Text(trailing)
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk3)
            }
            if showsChevron {
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
            }
        }
        .frame(minHeight: subtitle == nil ? 52 : 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
