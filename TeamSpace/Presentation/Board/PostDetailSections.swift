import SwiftUI

/// 10-3 위 — 분류 · 익명 게시글 배지 · 제목 · 작성자 · 시각 · 조회 · 본문
struct PostDetailHeader: View {
    let detail: PostDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: detail.post.category, size: .small)
                if detail.post.isPinned {
                    StatusBadge(title: "고정", tone: .primary, size: .small)
                }
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
                PostAuthorAvatar(isAnonymous: detail.post.isAnonymous, photo: detail.post.authorPhoto, size: 36)
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
    var photo: ProfilePhoto?
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
            AvatarView(size: size, photo: photo)
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
                .frame(minHeight: 34)
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
                .frame(minHeight: 34)
                .background(Color.tsSurface, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

/// 10-3 댓글 — 운영 방식 안내 · 댓글 목록
struct PostCommentSection: View {
    let detail: PostDetail
    var likingCommentIds: Set<Int> = []
    var onLikeComment: (Int) -> Void = { _ in }
    /// 내 댓글 · Admin 에게만 더보기(고치기 · 지우기)를 보여줘요.
    var canEdit: (PostComment) -> Bool = { _ in false }
    var canDelete: (PostComment) -> Bool = { _ in false }
    var onEditComment: (PostComment) -> Void = { _ in }
    var onDeleteComment: (PostComment) -> Void = { _ in }

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
                PostCommentRow(
                    comment: comment,
                    isLiking: likingCommentIds.contains(comment.id),
                    canEdit: canEdit(comment),
                    canDelete: canDelete(comment),
                    onLike: { onLikeComment(comment.id) },
                    onEdit: { onEditComment(comment) },
                    onDelete: { onDeleteComment(comment) }
                )
            }
        }
    }
}

private struct PostCommentRow: View {
    let comment: PostComment
    let isLiking: Bool
    var canEdit = false
    var canDelete = false
    let onLike: () -> Void
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            PostAuthorAvatar(isAnonymous: comment.isAnonymous, isHighlighted: comment.isPostAuthor, photo: comment.authorPhoto)
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
                    .accessibilityElement(children: .combine)
                // Figma 10-3b — 공감 전 회색 빈 하트, 공감하면 빨간 하트 · 숫자
                Button(action: onLike) {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                            .tsIconSize(.xs)
                        Text("공감 \(comment.likeCount)")
                            .tsFont(.caption2)
                    }
                    .foregroundStyle(comment.isLiked ? Color.tsNegative : Color.tsInk3)
                    .frame(minHeight: 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLiking)
                .accessibilityLabel("댓글 공감 \(comment.likeCount)")
                .accessibilityAddTraits(comment.isLiked ? .isSelected : [])
            }
            Spacer(minLength: 0)
            if canEdit || canDelete {
                Menu {
                    if canEdit {
                        Button("수정하기", action: onEdit)
                    }
                    if canDelete {
                        Button("삭제하기", role: .destructive, action: onDelete)
                    }
                } label: {
                    TSIcon.ellipsis.sized(.sm)
                        .foregroundStyle(Color.tsInk3)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("댓글 더보기")
            }
        }
    }
}

/// 댓글 고치기 시트 — 본문만 고쳐요. (익명 여부는 그대로)
struct CommentEditSheet: View {
    @Bindable var viewModel: PostDetailViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Button("취소") { viewModel.cancelEditing() }
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk2)
                Spacer()
                Text("댓글 수정")
                    .tsFont(.headline)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("저장") { Task { await viewModel.saveComment() } }
                    .tsFont(.calloutBold)
                    .foregroundStyle(viewModel.canSaveComment ? Color.tsPrimary : Color.tsInk3)
                    .disabled(!viewModel.canSaveComment)
            }
            TextEditor(text: $viewModel.editingCommentText)
                .tsFont(.body)
                .foregroundStyle(Color.tsInk)
                .scrollContentBackground(.hidden)
                .padding(Spacing.md)
                .frame(minHeight: 160)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .focused($isFocused)
            Text("\(TSFormat.number(viewModel.editingCommentText.count)) / \(TSFormat.number(CommentDraft.bodyLimit))")
                .tsFont(.caption2)
                .foregroundStyle(viewModel.editingCommentText.count > CommentDraft.bodyLimit ? Color.tsNegative : Color.tsInk3)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer(minLength: 0)
        }
        .padding(Spacing.screen)
        .background(Color.tsBackground.ignoresSafeArea())
        .onAppear { isFocused = true }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(viewModel.isSavingComment)
    }
}
