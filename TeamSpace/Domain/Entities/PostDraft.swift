import Foundation

/// 10-2 게시글 작성 내용 (임시 저장도 이 모양 그대로 — 사진은 저장하지 않아요)
struct PostDraft: Equatable, Codable, Sendable {
    static let titleLimit = 60
    static let bodyLimit = 5_000
    /// 사진은 최대 5장 · 장당 10MB
    static let imageLimit = 5
    static let imageByteLimit = 10 * 1_024 * 1_024

    var isAnonymous = true
    var category: PostCategory?
    var title = ""
    var body = ""
    var commentPolicy: CommentPolicy = .anonymous

    var isEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// 10-4 댓글 작성 내용
struct CommentDraft: Equatable, Sendable {
    static let bodyLimit = 1_000

    var isAnonymous: Bool
    var body = ""
}
