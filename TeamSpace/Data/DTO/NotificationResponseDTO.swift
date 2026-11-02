import Foundation

/// GET /notifications 응답의 `data` — 서버(develop)는 `{ items, nextCursor }`, 예전 명세서 예시는 `{ list }`
struct NotificationListResponseDTO: Decodable {
    let items: [NotificationResponseDTO]
    let nextCursor: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([NotificationResponseDTO].self, forKey: .items)
            ?? container.decode([NotificationResponseDTO].self, forKey: .list)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case list
        case nextCursor
    }

    func toEntity() -> CursorPage<AppNotification> {
        CursorPage(items: items.map { $0.toEntity() }, nextCursor: nextCursor)
    }
}

/// 알림 한 개 (TeamSpace-backend `account.py` · `shared.notify_user`)
/// 서버: `{ id: "12", kind: "내 업무|재정|일정|공지", sourceKind, title, createdAt, href: "/inhouse/...", unread, action }`
/// 예전 명세서 `{ id, type, deepLink, isRead }` 도 읽어요.
struct NotificationResponseDTO: Decodable {
    let id: Int
    let type: NotificationType
    let title: String
    /// 서버에 본문이 없어요 — `message` · 프런트 `meta` 가 오면 사용
    let message: String?
    let deepLink: String?
    let isRead: Bool
    let createdAt: Date
    /// 서버에 없는 필드 — 규칙 알림의 시행일
    let effectiveAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, type, kind, sourceKind, title, message, meta, href, deepLink, unread, isRead, action, createdAt, effectiveAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        message = (try? container.decodeIfPresent(String.self, forKey: .message))
            ?? (try? container.decodeIfPresent(String.self, forKey: .meta))
        let href = (try? container.decodeIfPresent(String.self, forKey: .href))
            ?? (try? container.decodeIfPresent(String.self, forKey: .deepLink))
        let action = (try? container.decodeIfPresent(Bool.self, forKey: .action)) ?? false
        type = Self.type(
            legacy: try? container.decodeIfPresent(String.self, forKey: .type),
            kind: (try? container.decodeIfPresent(String.self, forKey: .sourceKind))
                ?? (try? container.decodeIfPresent(String.self, forKey: .kind)),
            href: href,
            action: action
        )
        deepLink = href.map(Self.appPath)
        if let unread = try? container.decodeIfPresent(Bool.self, forKey: .unread) {
            isRead = !unread
        } else {
            isRead = (try? container.decodeIfPresent(Bool.self, forKey: .isRead)) ?? false
        }
        createdAt = Self.date(container, .createdAt) ?? .distantPast
        effectiveAt = Self.date(container, .effectiveAt)
    }

    private static func date(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Date? {
        if let text = try? container.decodeIfPresent(String.self, forKey: key) { return ServerDate.parse(text) }
        return try? container.decodeIfPresent(Date.self, forKey: key)
    }

    /// 서버는 종류를 한글 `kind` 4개로만 줘서, 이동 경로(href)로 결재 · 문의 · 규칙을 나눠요.
    static func type(legacy: String?, kind: String?, href: String?, action: Bool) -> NotificationType {
        if let legacy {
            if legacy == "INQUIRY_ANSWERED" { return .inquiryAnswer }
            if let known = NotificationType(rawValue: legacy) { return known }
        }
        let path = (href ?? "").components(separatedBy: "?")[0]
        let parts = Set(path.split(separator: "/").map(String.init))
        if path.contains("/inquir") { return .inquiryAnswer }
        if path.contains("/requests/") || path.contains("/approvals/") { return action ? .approval : .approvalResult }
        if !parts.isDisjoint(with: ["documents", "docs", "rules"]) { return .rule }
        switch kind {
        case "내 업무": return action ? .approval : .approvalResult
        case "재정": return .finance
        case "일정": return .schedule
        case "공지", "게시판": return .notice
        default: return .unknown
        }
    }

    /// 웹 경로 → 앱 경로. "/inhouse/community/notices/3" → "/notices/3", "/inhouse/community/inquiry?id=42" → "/inquiries/42"
    static func appPath(_ href: String) -> String {
        var path = href
        var query = ""
        if let mark = href.firstIndex(of: "?") {
            path = String(href[..<mark])
            query = String(href[href.index(after: mark)...])
        }
        if path.hasPrefix("/inhouse") { path = String(path.dropFirst("/inhouse".count)) }
        if path.contains("/inquir") {
            let id = query.split(separator: "&").first { $0.hasPrefix("id=") }.map { String($0.dropFirst(3)) }
            return id.map { "/inquiries/\($0)" } ?? "/inquiries"
        }
        let replacements = [
            ("/community/notices", "/notices"),
            ("/documents", "/rules"),
            ("/requests", "/approvals"),
            ("/community/proposals", "/proposals")
        ]
        for (web, app) in replacements where path.hasPrefix(web) {
            return app + path.dropFirst(web.count)
        }
        return path.isEmpty ? "/" : path
    }

    func toEntity() -> AppNotification {
        AppNotification(
            id: id,
            type: type,
            title: title,
            message: message,
            deepLink: deepLink,
            isRead: isRead,
            createdAt: createdAt,
            effectiveAt: effectiveAt
        )
    }
}

/// POST /notifications/read 요청 — 하나는 `{ id }`, 전부는 `{ all: true }`
struct NotificationReadRequestDTO: Encodable {
    let id: String?
    let all: Bool

    private enum CodingKeys: String, CodingKey { case id, all }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        if all { try container.encode(true, forKey: .all) }
    }
}

/// POST /notifications/read 응답 — `{ updated: n }`
struct NotificationReadResponseDTO: Decodable {
    let updated: Int?
}
