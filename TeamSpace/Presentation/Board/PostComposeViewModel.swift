import Foundation
import Observation

/// 10-2 게시글 작성 · 10-9 게시 완료
@Observable
@MainActor
final class PostComposeViewModel {
    /// 고른 사진 한 장 (JPG · PNG 데이터)
    struct Attachment: Identifiable, Equatable {
        let id = UUID()
        let data: Data
    }

    var draft = PostDraft()
    private(set) var attachments: [Attachment] = []
    private(set) var isSubmitting = false
    /// 10-9 — 올린 글 (알림을 띄워요)
    var publishedPost: PostSummary?
    /// 임시 저장한 글을 불러왔는지
    private(set) var didRestoreDraft = false
    var errorMessage: String?

    private let createPostUseCase: CreatePostUseCase
    private let postDraftUseCase: PostDraftUseCase

    init(createPostUseCase: CreatePostUseCase, postDraftUseCase: PostDraftUseCase) {
        self.createPostUseCase = createPostUseCase
        self.postDraftUseCase = postDraftUseCase
        if let saved = postDraftUseCase.fetch() {
            draft = saved
            didRestoreDraft = true
        }
    }

    /// "익명으로 게시해요. 이름과 소속은 구성원에게 표시되지 않아요."
    var authorNotice: String {
        draft.isAnonymous
            ? "익명으로 게시해요. 이름과 소속은 구성원에게 표시되지 않아요."
            : "실명으로 게시해요. 이름과 소속이 구성원에게 함께 보여요."
    }

    /// "96 / 5,000"
    var bodyCountText: String {
        "\(TSFormat.number(draft.body.count)) / \(TSFormat.number(PostDraft.bodyLimit))"
    }

    var isBodyOverLimit: Bool { draft.body.count > PostDraft.bodyLimit }

    var canAddImage: Bool { attachments.count < PostDraft.imageLimit }

    /// 사진 칸 옆 "2 / 5"
    var imageCountText: String { "\(attachments.count) / \(PostDraft.imageLimit)" }

    var publishTitle: String { draft.isAnonymous ? "익명으로 게시하기" : "실명으로 게시하기" }

    var canPublish: Bool {
        !isSubmitting
            && draft.category != nil
            && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.title.count <= PostDraft.titleLimit
            && !isBodyOverLimit
    }

    /// 10-9 알림 문구
    var completionMessage: String {
        guard let post = publishedPost else { return "" }
        return post.isAnonymous
            ? "익명으로 게시되어 작성자는 표시되지 않아요."
            : "실명으로 게시되어 이름과 소속이 함께 보여요."
    }

    func setAnonymous(_ isAnonymous: Bool) {
        draft.isAnonymous = isAnonymous
    }

    /// 사진 추가 — JPG · PNG, 장당 10MB, 최대 5장
    func addImages(_ images: [Data]) {
        var rejected = 0
        for data in images {
            if canAddImage, Self.isJPEGOrPNG(data), data.count <= PostDraft.imageByteLimit {
                attachments.append(Attachment(data: data))
            } else {
                rejected += 1
            }
        }
        if rejected > 0 {
            errorMessage = "JPG · PNG 사진만, 최대 \(PostDraft.imageLimit)장 · 장당 10MB까지 올릴 수 있어요."
        }
    }

    func removeImage(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
    }

    /// "임시 저장" — 빈 글이면 저장하지 않아요.
    @discardableResult
    func saveDraft() -> Bool {
        postDraftUseCase.save(draft)
    }

    func publish() async {
        guard canPublish else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            publishedPost = try await createPostUseCase.execute(draft, images: attachments.map(\.data))
        } catch {
            AppLog.record(error, context: "board.post.create")
            errorMessage = error.userMessage
        }
    }

    static func isJPEGOrPNG(_ data: Data) -> Bool {
        let bytes = [UInt8](data.prefix(4))
        let isJPEG = bytes.starts(with: [0xFF, 0xD8])
        let isPNG = bytes == [0x89, 0x50, 0x4E, 0x47]
        return isJPEG || isPNG
    }
}
