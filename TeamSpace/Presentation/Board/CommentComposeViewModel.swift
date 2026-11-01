import Foundation
import Observation

/// 10-4 댓글 작성 — 실명 · 익명은 댓글 쓰는 사람이 골라요.
@Observable
@MainActor
final class CommentComposeViewModel {
    private(set) var state: ViewState<PostDetail> = .idle
    var draft: CommentDraft
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    var errorMessage: String?

    let userName: String
    private let postId: Int
    private let fetchPostDetailUseCase: FetchPostDetailUseCase
    private let createCommentUseCase: CreateCommentUseCase

    init(
        postId: Int,
        userName: String,
        fetchPostDetailUseCase: FetchPostDetailUseCase,
        createCommentUseCase: CreateCommentUseCase
    ) {
        self.postId = postId
        self.userName = userName
        self.fetchPostDetailUseCase = fetchPostDetailUseCase
        self.createCommentUseCase = createCommentUseCase
        self.draft = CommentDraft(isAnonymous: true)
    }

    var post: PostDetail? { state.value }

    /// "원글 · 김민규 · 실명 · 10.14"
    var originText: String {
        guard let post = post?.post else { return "" }
        let author = post.isAnonymous ? "익명" : "\(post.authorName ?? "익명") · 실명"
        return "원글 · \(author) · \(TSFormat.shortDate(post.createdAt))"
    }

    /// "실명 · 옥물결"
    var realNameTitle: String { "실명 · \(userName)" }

    /// 미리보기 이름
    var previewName: String { draft.isAnonymous ? "익명" : userName }

    var previewBody: String {
        let body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? "댓글 내용을 쓰면 여기에 미리 보여요." : body
    }

    /// "방금 · 익명 댓글 미리보기"
    var previewMeta: String { "방금 · \(draft.isAnonymous ? "익명" : "실명") 댓글 미리보기" }

    /// "120 / 1,000"
    var countText: String { "\(TSFormat.number(draft.body.count)) / \(TSFormat.number(CommentDraft.bodyLimit))" }

    var submitTitle: String { draft.isAnonymous ? "익명으로 댓글 등록" : "실명으로 댓글 등록" }

    var canSubmit: Bool {
        let count = draft.body.trimmingCharacters(in: .whitespacesAndNewlines).count
        return !isSubmitting && count > 0 && draft.body.count <= CommentDraft.bodyLimit
    }

    /// 원글의 댓글 정책을 기본값으로 써요.
    func load() async {
        guard state.value == nil else { return }
        state = .loading
        do {
            let detail = try await fetchPostDetailUseCase.execute(id: postId)
            draft.isAnonymous = detail.commentPolicy != .realName
            state = .loaded(detail)
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "board.comment.load")
            state = .failed(error)
        }
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await createCommentUseCase.execute(postId: postId, draft: draft)
            didSubmit = true
        } catch {
            AppLog.record(error, context: "board.comment.create")
            errorMessage = error.userMessage
        }
    }
}
