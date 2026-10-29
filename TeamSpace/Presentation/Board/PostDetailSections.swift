import SwiftUI

/// 10-3 위 — 분류 · 익명 게시글 배지 · 제목 · 작성자 · 시각 · 조회 · 본문
struct PostDetailHeader: View {
    let detail: PostDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: detail.post.category, size: .small)
                if detail.post.isAnonymous {
                    StatusBadge(title: "익명 게시글", tone: .neutral, size: .small)
                }
            }
            Text(detail.post.title)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                PostAuthorAvatar(isAnonymous: detail.post.isAnonymous, size: 36)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(detail.post.authorText)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    Text(detail.metaText())
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            .accessibilityElement(children: .combine)
            TSDivider()
            Text(detail.body)
                .tsFont(.body)
                .foregroundStyle(Color.tsInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 익명은 가면 아이콘, 실명은 미모티콘 자리 (글쓴이 댓글은 노란 배경)
struct PostAuthorAvatar: View {
    let isAnonymous: Bool
    var isHighlighted = false
    var size: CGFloat = 32

    var body: some View {
        if isAnonymous {
            IconTile(
                icon: .anonymous,
                iconSize: .md,
                tileSize: size,
                tint: isHighlighted ? .tsAmber : .tsInk2,
                background: isHighlighted ? .tsAmberSoft : .tsSurface2,
                isCircle: true
            )
        } else {
            AvatarView(size: size)
        }
    }
}

/// 10-3 공감 · 링크 복사
struct PostReactionBar: View {
    let detail: PostDetail
    let isLiking: Bool
    let onLike: () -> Void
    let onCopyLink: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: onLike) {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: detail.isLiked ? "heart.fill" : "heart")
                        .tsIconSize(.sm)
                    Text("공감 \(detail.post.likeCount)")
                        .tsFont(.captionBold)
                }
                .foregroundStyle(detail.isLiked ? Color.tsNegative : Color.tsInk2)
                .padding(.horizontal, Spacing.md)
                .frame(height: 34)
                .background(detail.isLiked ? Color.tsNegativeSoft : Color.tsSurface, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLiking)
            .accessibilityAddTraits(detail.isLiked ? .isSelected : [])
            Button(action: onCopyLink) {
                HStack(spacing: Spacing.xxs) {
                    TSIcon.link.sized(.sm)
                    Text("링크 복사")
                        .tsFont(.captionBold)
                }
                .foregroundStyle(Color.tsInk2)
                .padding(.horizontal, Spacing.md)
                .frame(height: 34)
                .background(Color.tsSurface, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

/// 10-3 댓글 — 운영 방식 안내 · 댓글 목록
struct PostCommentSection: View {
    let detail: PostDetail

    var body: some View {
        WorkspaceCard {
            HStack(spacing: Spacing.xs) {
                WorkspaceCardTitle(title: "댓글")
                StatusBadge(title: "\(detail.comments.count)", tone: .primaryFilled, size: .small)
            }
            HStack(spacing: Spacing.xs) {
                TSIcon.anonymous.sized(.sm)
                Text(detail.policyText)
                    .tsFont(.caption2)
            }
            .foregroundStyle(Color.tsInk3)
            if detail.comments.isEmpty {
                Text("아직 댓글이 없어요. 첫 댓글을 남겨보세요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(detail.comments) { comment in
                TSDivider()
                PostCommentRow(comment: comment)
            }
        }
    }
}

private struct PostCommentRow: View {
    let comment: PostComment

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            PostAuthorAvatar(isAnonymous: comment.isAnonymous, isHighlighted: comment.isPostAuthor)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(comment.authorText)
                        .tsFont(.captionBold)
                        .foregroundStyle(comment.isPostAuthor ? Color.tsAmber : Color.tsInk)
                    Text(comment.timeText())
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text(comment.body)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
