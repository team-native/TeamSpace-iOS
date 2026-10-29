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
    private(set) var isDeleted = false
    var isMorePresented = false
    var isReportPresented = false
    var toastMessage: String?
    var errorMessage: String?

    let postId: Int
    private let fetchPostDetailUseCase: FetchPostDetailUseCase
    private let togglePostLikeUseCase: TogglePostLikeUseCase
    private let reportPostUseCase: ReportPostUseCase
    private let deletePostUseCase: DeletePostUseCase

    init(
        postId: Int,
        fetchPostDetailUseCase: FetchPostDetailUseCase,
        togglePostLikeUseCase: TogglePostLikeUseCase,
        reportPostUseCase: ReportPostUseCase,
        deletePostUseCase: DeletePostUseCase
    ) {
        self.postId = postId
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
