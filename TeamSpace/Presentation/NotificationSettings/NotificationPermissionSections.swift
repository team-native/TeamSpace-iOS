import SwiftUI

/// 02-6 잠금 화면 알림 예시 카드 (그라디언트 배경)
struct NotificationPreviewCard: View {
    let hidesSensitive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            IconTile(icon: .clipboardCheck, tint: .tsOnPrimary, background: .tsPrimary)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    Text("TeamSpace")
                        .tsFont(.captionBold)
                        .foregroundStyle(Color.tsInk2)
                    Spacer()
                    Text("지금")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text("결재 요청이 도착했어요")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(hidesSensitive ? "앱에서 내용을 확인해 주세요." : "3월 정기 행사 지출 결의서 · 128,000원")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
            }
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface.opacity(0.85), in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .padding(Spacing.lg)
        .background(TSGradient.notificationPreview, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("알림 예시")
    }
}

/// 02-6 "이런 소식을 알려드려요"
struct NotificationTopicList: View {
    private let topics: [NotificationSettingCategory] = [.personalTask, .finance, .schedule, .notice]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("이런 소식을 알려드려요")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: Spacing.md) {
                ForEach(topics, id: \.self) { topic in
                    HStack(spacing: Spacing.md) {
                        IconTile(icon: topic.icon, iconSize: .base, tileSize: 32, tint: topic.tint, background: topic.tileBackground)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(topic.title)
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            Text(topic.detail)
                                .tsFont(.caption)
                                .foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .tsCard(padding: Spacing.lg)
        }
    }
}

/// 02-6 잠금 화면 미리보기 선택 (라디오)
struct LockScreenPreviewPicker: View {
    let options: [LockScreenPreview]
    let selection: LockScreenPreview
    let onSelect: (LockScreenPreview) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("잠금 화면 미리보기")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    RadioRow(title: option.title, detail: option.detail, isSelected: option == selection)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
    }
}

private struct RadioRow: View {
    let title: String
    let detail: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.tsPrimary : Color.tsSurface)
                    .overlay { Circle().stroke(isSelected ? Color.tsPrimary : Color.tsLine, lineWidth: 1.5) }
                if isSelected {
                    TSIcon.checkSmall.sized(.sm)
                        .foregroundStyle(Color.tsOnPrimary)
                }
            }
            .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(detail)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .stroke(isSelected ? Color.tsPrimary : Color.tsLine, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            NotificationPreviewCard(hidesSensitive: false)
            NotificationTopicList()
            LockScreenPreviewPicker(options: LockScreenPreview.allCases, selection: .hideSensitive, onSelect: { _ in })
        }
        .padding()
    }
    .background(Color.tsBackground)
}
