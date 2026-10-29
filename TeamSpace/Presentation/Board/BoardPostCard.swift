import SwiftUI

/// 10-1 게시글 카드 — 분류 · 시각 · 제목 · 미리보기 · 작성자 · 공감 · 댓글
struct BoardPostCard: View {
    let post: PostSummary
    var now = Date()
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            WorkspaceCard {
                HStack {
                    StatusBadge(status: post.category, size: .small)
                    Spacer(minLength: Spacing.sm)
                    Text(TSFormat.dayTime(post.createdAt, now: now))
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(post.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .lineLimit(1)
                    Text(post.excerpt)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                TSDivider()
                footer
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        HStack(spacing: Spacing.sm) {
            BoardAuthorLabel(post: post)
            Spacer(minLength: Spacing.sm)
            BoardCountLabel(icon: .heart, count: post.likeCount, label: "공감")
            BoardCountLabel(icon: .message, count: post.commentCount, label: "댓글")
        }
    }
}

/// 작성자 — 익명은 가면 아이콘, 실명은 미모티콘 자리
struct BoardAuthorLabel: View {
    let post: PostSummary

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if post.isAnonymous {
                IconTile(icon: .anonymous, iconSize: .sm, tileSize: 22, tint: .tsInk2, background: .tsSurface2, isCircle: true)
            } else {
                AvatarView(size: 22)
            }
            Text(post.authorText)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .lineLimit(1)
        }
    }
}

/// 하트 12 · 말풍선 2
struct BoardCountLabel: View {
    let icon: TSIcon
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            icon.sized(.sm)
            Text("\(count)")
                .tsFont(.captionBold)
        }
        .foregroundStyle(Color.tsInk3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(count)")
    }
}
