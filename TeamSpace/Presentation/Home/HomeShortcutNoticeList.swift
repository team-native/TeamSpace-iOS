import SwiftUI

/// 02-1 지금 팀이 알아야 할 것들
struct HomeNoticeList: View {
    let notices: [NoticePreview]
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            SectionTitle(title: "지금 팀이 알아야 할 것들", linkTitle: "전체 보기", onLink: onShowAll)
            VStack(spacing: 0) {
                ForEach(Array(notices.enumerated()), id: \.element.id) { index, notice in
                    if index > 0 { TSDivider() }
                    Button(action: onShowAll) {
                        NoticeRow(notice: notice)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xxs)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

private struct NoticeRow: View {
    let notice: NoticePreview

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: Spacing.xs) {
                    CategoryChip(title: notice.category.title, tone: notice.category.tone)
                    Text(TSFormat.updated(notice.updatedAt))
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text(notice.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            TSIcon.chevronRight.sized(.mdLarge)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.vertical, Spacing.md + Spacing.xxxs)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        HomeNoticeList(
            notices: [NoticePreview(id: 1, category: .finance, title: "10월 프로젝트 정산 기준 안내", updatedAt: Date())],
            onShowAll: {}
        )
    }
    .padding()
    .background(Color.tsBackground)
}
