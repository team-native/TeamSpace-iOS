import Foundation

/// 10-2 게시하기 — 분류 · 제목 · 본문 · 사진 수를 확인하고, 올리면 임시 저장은 지워요.
struct CreatePostUseCase {
    private let boardRepository: BoardRepository
    private let postDraftRepository: PostDraftRepository

    init(boardRepository: BoardRepository, postDraftRepository: PostDraftRepository) {
        self.boardRepository = boardRepository
        self.postDraftRepository = postDraftRepository
    }

    func execute(_ draft: PostDraft, images: [Data]) async throws -> PostSummary {
        var trimmed = draft
        trimmed.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed.body = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.category != nil else { throw AppError.invalidInput("카테고리를 골라 주세요.") }
        guard !trimmed.title.isEmpty, trimmed.title.count <= PostDraft.titleLimit else {
            throw AppError.invalidInput("제목은 1~\(PostDraft.titleLimit)자로 써 주세요.")
        }
        guard !trimmed.body.isEmpty, trimmed.body.count <= PostDraft.bodyLimit else {
            throw AppError.invalidInput("본문은 1~\(PostDraft.bodyLimit)자로 써 주세요.")
        }
        guard images.count <= PostDraft.imageLimit else {
            throw AppError.invalidInput("사진은 최대 \(PostDraft.imageLimit)장까지 올릴 수 있어요.")
        }
        let post = try await boardRepository.createPost(trimmed, images: images)
        postDraftRepository.clear()
        return post
    }
}
