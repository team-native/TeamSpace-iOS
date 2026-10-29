import Foundation

/// 게시글 분류 (Figma 10-1 수정본: 자유 · 질문 · 정보공유)
enum PostCategory: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case free = "FREE"
    case question = "QUESTION"
    case info = "INFO"
    case unknown = "UNKNOWN"

    static let unknownCase: PostCategory = .unknown
    static let selectable: [PostCategory] = [.free, .question, .info]
}

/// 10-1 게시글 카드 한 건
struct PostSummary: Equatable, Identifiable, Sendable {
    let id: Int
    let category: PostCategory
    let title: String
    let excerpt: String
    /// 익명 글이면 nil
    let authorName: String?
    /// 예) "Leader"
    let authorRole: String?
    let isAnonymous: Bool
    let createdAt: Date
    let likeCount: Int
    let commentCount: Int
    let viewCount: Int
    let hasImage: Bool
    /// 내가 쓴 글 (익명이어도 본인에게는 알려줘요)
    let isMine: Bool
}
