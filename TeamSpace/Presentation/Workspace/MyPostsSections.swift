import SwiftUI

/// 07-10 게시글 카드 — 작성 시각 · 실명/익명 · 제목 · 반응 · 상세 보기
struct MyPostCard: View {
    let post: MyPost
    let authorName: String
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(post.metaText(authorName: authorName))
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(title: post.badgeTitle, tone: post.isAnonymous ? .neutral : .primary, size: .small)
            }
            WorkspaceItemText(title: post.title, meta: post.statsText)
            WorkspaceLinkRow(title: "상세 보기 · 수정", action: onOpen)
        }
    }
}

/// 07-10 댓글 한 건 (인용 · 원글 · 반응)
private struct CommentBody: View {
    let comment: MyComment

    var body: some View {
        StatusBadge(title: comment.badgeTitle, tone: comment.isAnonymous ? .neutral : .primary, size: .small)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(comment.quoteText)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            Text(comment.metaText)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 07-10 글 탭 아래 — 최근 작성한 댓글 + 댓글 탭으로
struct RecentCommentCard: View {
    let comment: MyComment
    let onShowComments: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "최근 작성한 댓글")
            CommentBody(comment: comment)
            Button("댓글 탭에서 확인 · 수정", action: onShowComments)
                .buttonStyle(.tsSecondary)
        }
    }
}

/// 07-10 댓글 탭 카드
struct MyCommentCard: View {
    let comment: MyComment
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            CommentBody(comment: comment)
            WorkspaceLinkRow(title: "원글 보기", action: onOpen)
        }
    }
}
