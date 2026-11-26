import Foundation
import Observation

/// 10-3 게시글 상세 · 10-8 더보기 · 10-10 신고 · 10-11 링크 복사
@Observable
@MainActor
final class PostDetailViewModel {
    /// 더보기 시트가 닫히고 신고 시트를 띄우기까지 기다리는 시간
    static let sheetSwapNanoseconds: UInt64 = 350_000_000

    private(set) var state: ViewState<PostDetail> = .idle
    private(set) var isLiking = false
    /// 공감 요청 중인 댓글 (연속 탭 막기)
    private(set) var likingCommentIds: Set<Int> = []
    private(set) var isDeleted = false
    var isMorePresented = false
    var isReportPresented = false
    /// 고치는 중인 댓글 · 입력 중인 글
    var editingComment: PostComment?
    var editingCommentText = ""
    /// 지울지 묻는 댓글
    var deletingComment: PostComment?
    private(set) var isSavingComment = false
    private(set) var isPinning = false
    var toastMessage: String?
    var errorMessage: String?

    let postId: Int
    /// Admin — 고정 · 남의 댓글 지우기
    let canModerate: Bool
    private let fetchPostDetailUseCase: FetchPostDetailUseCase
    private let togglePostLikeUseCase: TogglePostLikeUseCase
    private let reportPostUseCase: ReportPostUseCase
    private let deletePostUseCase: DeletePostUseCase
    private let managePostCommentUseCase: ManagePostCommentUseCase
    private let pinPostUseCase: PinPostUseCase
    /// 첨부 사진 받기 · 크게 보기
    let attachmentDownloader: AttachmentDownloadViewModel?

    init(
        postId: Int,
        canModerate: Bool = false,
        fetchPostDetailUseCase: FetchPostDetailUseCase,
        togglePostLikeUseCase: TogglePostLikeUseCase,
        reportPostUseCase: ReportPostUseCase,
        deletePostUseCase: DeletePostUseCase,
        managePostCommentUseCase: ManagePostCommentUseCase,
        pinPostUseCase: PinPostUseCase,
        attachmentDownloader: AttachmentDownloadViewModel? = nil
    ) {
        self.attachmentDownloader = attachmentDownloader
        self.postId = postId
        self.canModerate = canModerate
        self.managePostCommentUseCase = managePostCommentUseCase
        self.pinPostUseCase = pinPostUseCase
        self.fetchPostDetailUseCase = fetchPostDetailUseCase
        self.togglePostLikeUseCase = togglePostLikeUseCase
        self.reportPostUseCase = reportPostUseCase
        self.deletePostUseCase = deletePostUseCase
    }

    var detail: PostDetail? { state.value }

    /// 앱 안에서 다시 열 수 있는 주소
    var link: String { "teamspace://posts/\(postId)" }

    /// 내 글은 신고 대신 삭제
    var canReport: Bool { detail.map { !$0.post.isMine } ?? false }
    var canDelete: Bool { detail?.post.isMine ?? false }
    /// 내 글만 고칠 수 있어요. (PATCH /posts/{id})
    var canEdit: Bool { detail?.post.isMine ?? false }
    /// Admin 만 고정 · 해제 (PATCH /admin/posts/{id})
    var canPin: Bool { canModerate && detail != nil }
    var pinTitle: String { detail?.post.isPinned == true ? "고정 해제" : "상단에 고정" }

    /// 내 댓글은 고치기 · 지우기, Admin 은 남의 댓글도 지우기
    func canEditComment(_ comment: PostComment) -> Bool { comment.isMine }
    func canDeleteComment(_ comment: PostComment) -> Bool { comment.isMine || canModerate }

    var canSaveComment: Bool {
        let count = editingCommentText.trimmingCharacters(in: .whitespacesAndNewlines).count
        return !isSavingComment && count > 0 && count <= CommentDraft.bodyLimit
            && editingCommentText != editingComment?.body
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchPostDetailUseCase.execute(id: postId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "board.post.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func toggleLike() async {
        guard let detail = detail, !isLiking else { return }
        isLiking = true
        defer { isLiking = false }
        do {
            state = .loaded(try await togglePostLikeUseCase.execute(detail))
        } catch {
            AppLog.record(error, context: "board.post.like")
            errorMessage = error.userMessage
        }
    }

    /// 10-3b 댓글 공감 — 서버 결과로 그 댓글의 하트 · 수를 바꿔요.
    func toggleCommentLike(_ commentId: Int) async {
        guard detail != nil, !likingCommentIds.contains(commentId) else { return }
        likingCommentIds.insert(commentId)
        defer { likingCommentIds.remove(commentId) }
        do {
            guard let current = detail else { return }
            state = .loaded(try await togglePostLikeUseCase.execute(current, commentId: commentId))
        } catch {
            AppLog.record(error, context: "board.comment.like")
            errorMessage = error.userMessage
        }
    }

    /// 10-11 — 복사는 View 가 하고 토스트만 띄워요.
    func didCopyLink() {
        toastMessage = "링크를 복사했어요"
    }

    /// 10-8 → 10-10 시트 바꾸기
    func requestReport() async {
        isMorePresented = false
        try? await Task.sleep(nanoseconds: Self.sheetSwapNanoseconds)
        isReportPresented = true
    }

    func report(_ reason: PostReportReason) async {
        guard let post = detail?.post else { return }
        do {
            try await reportPostUseCase.execute(post: post, reason: reason)
            toastMessage = "신고를 접수했어요"
        } catch {
            AppLog.record(error, context: "board.post.report")
            errorMessage = error.userMessage
        }
    }

    // MARK: 댓글 고치기 · 지우기

    func startEditing(_ comment: PostComment) {
        editingCommentText = comment.body
        editingComment = comment
    }

    func cancelEditing() {
        editingComment = nil
        editingCommentText = ""
    }

    func saveComment() async {
        guard let comment = editingComment, let current = detail, canSaveComment else { return }
        isSavingComment = true
        defer { isSavingComment = false }
        do {
            state = .loaded(try await managePostCommentUseCase.update(current, commentId: comment.id, text: editingCommentText))
            cancelEditing()
            toastMessage = "댓글을 고쳤어요"
        } catch {
            AppLog.record(error, context: "board.comment.update")
            errorMessage = error.userMessage
        }
    }

    func deleteComment() async {
        guard let comment = deletingComment, let current = detail else { return }
        deletingComment = nil
        do {
            state = .loaded(try await managePostCommentUseCase.delete(current, commentId: comment.id, isAdmin: canModerate))
            toastMessage = "댓글을 지웠어요"
        } catch {
            AppLog.record(error, context: "board.comment.delete")
            errorMessage = error.userMessage
        }
    }

    // MARK: 10-8 상단 고정 (Admin)

    func togglePin() async {
        guard let current = detail, !isPinning else { return }
        isPinning = true
        defer { isPinning = false }
        let pin = !current.post.isPinned
        do {
            state = .loaded(try await pinPostUseCase.execute(current, isPinned: pin, isAdmin: canModerate))
            toastMessage = pin ? "게시글을 상단에 고정했어요" : "고정을 풀었어요"
        } catch {
            AppLog.record(error, context: "board.post.pin")
            errorMessage = error.userMessage
        }
    }

    func delete() async {
        guard let post = detail?.post else { return }
        do {
            try await deletePostUseCase.execute(post: post)
            isDeleted = true
        } catch {
            AppLog.record(error, context: "board.post.delete")
            errorMessage = error.userMessage
        }
    }
}
