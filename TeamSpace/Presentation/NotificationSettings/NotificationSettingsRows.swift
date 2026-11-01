import SwiftUI

/// 02-9 알림 종류 한 줄 — 아이콘 타일 + 제목 · 설명 + 토글
struct NotificationCategoryToggleRow: View {
    let category: NotificationSettingCategory
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                IconTile(icon: category.icon, tint: category.tint, background: category.tileBackground)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(category.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                    Text(category.detail)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.ts)
        .padding(.vertical, Spacing.md)
    }
}

/// 02-9 방해 금지 시간 카드
struct QuietHoursCard: View {
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: Spacing.md) {
                IconTile(icon: .moon, iconSize: .xlLarge, tint: .tsViolet, background: .tsVioletSoft)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("방해 금지 시간")
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                    Text(description)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
            }
        }
        .toggleStyle(.ts)
        .tsCard(padding: Spacing.lg)
    }
}

/// 기기 알림이 꺼져 있을 때 위에 보여주는 배너 → 02-6 / 02-7
struct PermissionOffBanner: View {
    /// true: 기기 설정에서 꺼짐(02-7) / false: 아직 묻지 않음(02-6)
    let isDenied: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                IconTile(icon: .bellOff, tint: .tsNegative, background: .tsNegativeSoft)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(isDenied ? "기기 알림이 꺼져 있어요" : "알림 권한이 아직 없어요")
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                    Text("결재 · 재정 소식을 바로 받으려면 알림을 켜 주세요.")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("켜기")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            .tsCard(padding: Spacing.lg)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        PermissionOffBanner(isDenied: true) {}
        NotificationCategoryToggleRow(category: .personalTask, isOn: .constant(true))
        QuietHoursCard(description: "22:00 – 08:00 에는 소리 없이 받아요", isOn: .constant(true))
    }
    .padding()
    .background(Color.tsBackground)
}
