import Foundation

/// 서버 목록 공통 `{ items, nextCursor }`
struct CursorPageDTO<Item: Decodable>: Decodable {
    let items: [Item]
    let nextCursor: String?
}

/// GET /posts 의 한 항목 (TeamSpace-backend `community._post_view`)
struct ServerPostItemDTO: Decodable {
    static let excerptLength = 80

    let id: Int
    let category: String
    let title: String
    let body: String
    let anonymous: Bool
    let views: Int
    let likes: Int
    let createdAt: Date
    let mine: Bool
    let commentCount: Int
    let attachmentCount: Int
    /// 익명 글이면 없어요.
    let author: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "자유"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        anonymous = try container.decodeIfPresent(Bool.self, forKey: .anonymous) ?? false
        views = try container.decodeIfPresent(Int.self, forKey: .views) ?? 0
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        mine = try container.decodeIfPresent(Bool.self, forKey: .mine) ?? false
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        attachmentCount = try container.decodeIfPresent([IgnoredJSONValue].self, forKey: .attachments)?.count ?? 0
        author = try container.decodeIfPresent(String.self, forKey: .author)
    }

    private enum CodingKeys: String, CodingKey {
        case id, category, title, body, anonymous, views, likes, createdAt, mine, commentCount, attachments, author
    }

    func toEntity() -> PostSummary {
        PostSummary(
            id: id,
            category: PostCategory(serverValue: category),
            title: title,
            excerpt: Self.excerpt(of: body),
            authorName: anonymous ? nil : author,
            authorRole: nil,
            isAnonymous: anonymous,
            createdAt: createdAt,
            likeCount: likes,
            commentCount: commentCount,
            viewCount: views,
            hasImage: attachmentCount > 0,
            isMine: mine
        )
    }

    /// 목록 카드용 — 줄바꿈을 한 칸으로 줄이고 앞부분만 써요.
    static func excerpt(of body: String) -> String {
        let oneLine = body.split(whereSeparator: \.isNewline).joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        guard oneLine.count > excerptLength else { return oneLine }
        return String(oneLine.prefix(excerptLength)) + "…"
    }
}

/// GET /notices 의 한 항목 — 서버는 저장한 공지 내용을 그대로 펼쳐서 줘요.
struct ServerNoticeItemDTO: Decodable {
    let id: Int
    let kind: String?
    let title: String
    let body: String?
    let createdAt: Date?
    let updatedAt: Date?
    let pinned: Bool
    let mustRead: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        kind = try container.decodeIfPresent(String.self, forKey: .kind)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try? container.decodeIfPresent(Date.self, forKey: .updatedAt)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned) ?? false
        mustRead = try container.decodeIfPresent(Bool.self, forKey: .mustRead) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, title, body, createdAt, updatedAt, pinned, mustRead
    }

    func toEntity() -> NoticeSummary {
        NoticeSummary(
            id: id,
            category: NoticeCategory(serverKind: kind),
            title: title,
            summary: body.map(ServerPostItemDTO.excerpt(of:)),
            updatedAt: updatedAt ?? createdAt ?? Date(),
            isPinned: pinned,
            isImportant: mustRead
        )
    }
}

/// 값은 읽지 않고 개수만 셀 때 — 어떤 JSON 값이든 받아요.
struct IgnoredJSONValue: Decodable {
    init(from decoder: Decoder) throws {}
}

extension PostCategory {
    /// 서버는 한글 분류(`자유` · `질문` · `정보 공유`)를 써요. 예전 영문 값도 받아요.
    init(serverValue: String) {
        switch serverValue.trimmingCharacters(in: .whitespaces) {
        case "자유", "FREE": self = .free
        case "질문", "QUESTION": self = .question
        case "정보 공유", "정보공유", "정보", "INFO": self = .info
        default: self = .unknown
        }
    }

    /// GET /posts?category= 에 보내는 값
    var serverValue: String? {
        switch self {
        case .free: return "자유"
        case .question: return "질문"
        case .info: return "정보 공유"
        case .unknown: return nil
        }
    }
}

extension NoticeCategory {
    /// 서버 공지 `kind` (자유 문자열) → 앱 분류
    init(serverKind: String?) {
        let kind = serverKind ?? ""
        if kind.contains("재무") || kind.uppercased() == "FINANCE" {
            self = .finance
        } else if kind.contains("규칙") || kind.contains("제도") || kind.uppercased() == "RULE" {
            self = .rule
        } else {
            self = .notice
        }
    }
}

extension PostListQuery {
    /// GET /posts 쿼리
    func queryItems(cursor: String?, limit: Int) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "sort", value: sort == .likes ? "likes" : "latest"),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let value = category?.serverValue { items.append(URLQueryItem(name: "category", value: value)) }
        switch period {
        case .today: items.append(URLQueryItem(name: "period", value: "today"))
        case .week: items.append(URLQueryItem(name: "period", value: "week"))
        case .month: items.append(URLQueryItem(name: "period", value: "month"))
        case .all: items.append(URLQueryItem(name: "period", value: "all"))
        case .range(let from, let to):
            items.append(URLQueryItem(name: "period", value: "all"))
            items.append(URLQueryItem(name: "from", value: Self.day(min(from, to))))
            items.append(URLQueryItem(name: "to", value: Self.day(max(from, to))))
        }
        if let keyword, !keyword.isEmpty { items.append(URLQueryItem(name: "q", value: keyword)) }
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        return items
    }

    /// 서버 시간대(Asia/Seoul) 기준 날짜 — `YYYY-MM-DD`
    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
