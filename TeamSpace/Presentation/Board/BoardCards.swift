import SwiftUI

/// 10-1 고정 공지 — 공지를 누르면 10-6 공지 상세로 가요.
struct PinnedNoticeCard: View {
    let notices: [NoticeSummary]
    var now = Date()
    let onOpen: (NoticeSummary) -> Void

    var body: some View {
        WorkspaceCard {
            HStack(spacing: Spacing.xs) {
                TSIcon.pin.sized(.base)
                    .foregroundStyle(Color.tsPrimary)
                WorkspaceCardTitle(title: "고정 공지")
                Spacer()
                Text("\(notices.count)건")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(Array(notices.enumerated()), id: \.element.id) { index, notice in
                if index > 0 { TSDivider() }
                Button { onOpen(notice) } label: {
                    HStack(spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                StatusBadge(status: notice.category, size: .small)
                                Text(TSFormat.updated(notice.updatedAt, now: now))
                                    .tsFont(.caption2)
                                    .foregroundStyle(Color.tsInk3)
                            }
                            Text(notice.title)
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                                .lineLimit(1)
                        }
                        Spacer(minLength: Spacing.sm)
                        TSIcon.chevronRight.sized(.base)
                            .foregroundStyle(Color.tsInk3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 10-1 이번 주 인기글 — 순위 · 제목 · 작성자 · 추천 · 댓글 · (사진)
struct PopularPostsCard: View {
    let posts: [PostSummary]
    let rangeText: String
    let onOpen: (PostSummary) -> Void
    let onShowMore: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                WorkspaceCardTitle(title: "이번 주 인기글")
                Spacer()
                Text(rangeText)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                if index > 0 { TSDivider() }
                Button { onOpen(post) } label: {
                    PopularPostRow(rank: index + 1, post: post)
                }
                .buttonStyle(.plain)
            }
            TSDivider()
            WorkspaceLinkRow(title: "인기글 더 보기", action: onShowMore)
        }
    }
}

private struct PopularPostRow: View {
    let rank: Int
    let post: PostSummary

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("\(rank)")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsPrimary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(post.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
                Text(post.reactionText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: Spacing.sm)
            if post.hasImage {
                IconTile(icon: .photo, iconSize: .lg, tileSize: 44, tint: .tsInk3, background: .tsSurface2)
                    .accessibilityLabel("사진 있음")
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// 10-1 운영 제안 배너 — 12 운영 제안으로 이어져요.
struct BoardProposalCard: View {
    let onWrite: () -> Void
    let onBrowse: () -> Void

    var body: some View {
        WorkspaceCard(background: .tsPrimarySoft) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Native 운영, 이렇게 바꿔볼까요?")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text("불편했던 점이나 바라는 점을 제안해 주세요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
            }
            HStack(spacing: Spacing.sm) {
                Button("운영 제안 쓰기", action: onWrite)
                    .buttonStyle(.ts(.primary, size: .small))
                Button("제안 모아보기", action: onBrowse)
                    .buttonStyle(.ts(.secondary, size: .small))
            }
        }
    }
}

/// 10-1 기간 설정 시트 — 시작일 · 종료일
struct BoardPeriodSheet: View {
    let onApply: (BoardPeriod) -> Void

    @State private var start: Date
    @State private var end: Date
    @Environment(\.dismiss) private var dismiss

    init(period: BoardPeriod, now: Date = Date(), onApply: @escaping (BoardPeriod) -> Void) {
        self.onApply = onApply
        if case .custom(let start, let end) = period {
            _start = State(initialValue: start)
            _end = State(initialValue: end)
        } else {
            _start = State(initialValue: now.addingTimeInterval(-6 * 86_400))
            _end = State(initialValue: now)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("기간 설정")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CircleIconButton(icon: .close, accessibilityLabel: "닫기", size: 32) { dismiss() }
            }
            WorkspaceCard {
                DatePicker("시작일", selection: $start, in: ...end, displayedComponents: .date)
                TSDivider()
                DatePicker("종료일", selection: $end, in: start..., displayedComponents: .date)
            }
            .tsFont(.callout)
            Spacer(minLength: 0)
            Button("적용") {
                onApply(.custom(start: start, end: end))
                dismiss()
            }
            .buttonStyle(.tsPrimaryLarge)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.xl)
        .background(Color.tsBackground.ignoresSafeArea())
        .environment(\.locale, Locale(identifier: "ko_KR"))
    }
}
