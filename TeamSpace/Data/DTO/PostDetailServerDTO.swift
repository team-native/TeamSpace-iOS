import Foundation

/// GET /posts/{id} — 목록 항목 필드 + 익명 댓글 여부 + 댓글 (TeamSpace-backend `_post_view(detail=True)`)
struct ServerPostDetailDTO: Decodable {
    let post: ServerPostItemDTO
    let anonComments: Bool
    let comments: [ServerCommentDTO]

    init(from decoder: Decoder) throws {
        post = try ServerPostItemDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        anonComments = try container.decodeIfPresent(Bool.self, forKey: .anonComments) ?? false
        comments = try container.decodeIfPresent([ServerCommentDTO].self, forKey: .comments) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case anonComments, comments
    }

    /// 서버는 내가 공감했는지 알려주지 않아요 — 처음엔 꺼진 상태로 보여요.
    func toEntity() -> PostDetail {
        let summary = post.toEntity()
        return PostDetail(
            post: summary,
            body: post.body,
            commentPolicy: anonComments || post.anonymous ? .anonymous : .realName,
            isLiked: false,
            comments: comments.map { $0.toEntity(postAuthor: summary.authorName) }
        )
    }
}

/// 댓글 한 건 (`_comment_view`) — 익명 글에서 글쓴이가 단 댓글은 author 가 "글쓴이" 예요.
struct ServerCommentDTO: Decodable {
    static let postAuthorLabel = "글쓴이"

    let id: Int
    let anonymous: Bool
    let text: String
    let createdAt: Date
    let author: String?
    let mine: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        anonymous = try container.decodeIfPresent(Bool.self, forKey: .anonymous) ?? false
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        mine = try container.decodeIfPresent(Bool.self, forKey: .mine) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, anonymous, text, createdAt, author, mine
    }

    /// 서버는 익명 번호를 주지 않아 "익명"으로만 보여요.
    func toEntity(postAuthor: String?) -> PostComment {
        let isAnonymousPostAuthor = author == Self.postAuthorLabel
        let isAnonymous = anonymous || isAnonymousPostAuthor
        return PostComment(
            id: id,
            authorName: isAnonymous ? nil : author,
            isAnonymous: isAnonymous,
            anonymousNumber: nil,
            isPostAuthor: isAnonymousPostAuthor || (postAuthor != nil && author == postAuthor),
            isMine: mine,
            body: text,
            createdAt: createdAt
        )
    }
}

/// POST /posts 요청 (`PostCreate`)
struct ServerPostCreateRequestDTO: Codable {
    let category: String
    let title: String
    let body: String
    let anonymous: Bool
    let anonComments: Bool
    /// `POST /uploads` 로 받은 id
    let attachments: [String]
    var status = "published"
}

/// POST /posts/{id}/comments 요청
struct ServerCommentCreateRequestDTO: Codable {
    let text: String
    let anonymous: Bool
}

/// POST /posts/{id}/like 응답
struct ServerLikeResponseDTO: Codable {
    let liked: Bool
    let likes: Int
}

/// POST /posts/{id}/report 요청
struct ServerReportRequestDTO: Codable {
    let reason: String
}

/// `{ "id": "12", ... }` 처럼 id 만 쓰는 응답 (글 작성 · 업로드)
struct ServerIdResponseDTO: Decodable {
    let id: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? container.decode(Int.self, forKey: .id) {
            id = String(number)
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
    }
}

extension PostReportReason {
    /// 서버 `REPORT_REASONS`
    var serverValue: String {
        switch self {
        case .abuse: return "욕설·비하"
        case .privacy: return "개인정보 노출"
        case .spam: return "도배·광고"
        case .etc: return "기타"
        }
    }
}
