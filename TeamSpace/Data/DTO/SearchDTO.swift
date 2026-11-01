import Foundation

/// GET /search 응답의 `data` (TeamSpace-backend `app/api/search.py`)
struct SearchResponseDTO: Decodable {
    let query: String
    let items: [SearchItemDTO]
    let counts: [String: Int]
    let nextCursor: String?

    func toEntity() -> SearchResult {
        var mapped: [SearchCategory: Int] = [:]
        for (key, value) in counts {
            if let category = SearchCategory(rawValue: key) { mapped[category] = value }
        }
        return SearchResult(
            query: query,
            items: items.compactMap { $0.toEntity() },
            counts: mapped,
            nextCursor: nextCursor
        )
    }
}

struct SearchItemDTO: Decodable {
    let category: String
    let id: String
    let title: String
    let snippet: String?
    let createdAt: Date?
    let type: String?
    let version: String?
    let author: String?
    let comments: Int?
    let status: String?
    let likes: Int?
    let dept: String?
    let pm: String?
    let progress: Int?

    fileprivate enum CodingKeys: String, CodingKey {
        case category, id, title, snippet, createdAt, type, version, author, comments, status, likes, dept, pm, progress
    }

    /// 백엔드가 자유 형식(payload)이라 숫자 · 문자열이 섞여 와도 읽을 수 있게 느슨하게 풀어요.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        id = try container.decodeLossyString(forKey: .id) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        snippet = try? container.decodeIfPresent(String.self, forKey: .snippet)
        createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt)).flatMap(SearchItemDTO.parseDate)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        version = try container.decodeLossyString(forKey: .version)
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        comments = container.decodeLossyInt(forKey: .comments)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
        likes = container.decodeLossyInt(forKey: .likes)
        dept = try? container.decodeIfPresent(String.self, forKey: .dept)
        pm = try? container.decodeIfPresent(String.self, forKey: .pm)
        progress = container.decodeLossyInt(forKey: .progress)
    }

    /// "2026-10-15T09:00:00+00:00" · 소수점 초 포함 모두 읽어요.
    static func parseDate(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: text)
    }

    /// 모르는 분류는 버려요.
    func toEntity() -> SearchHit? {
        guard let category = SearchCategory(rawValue: category) else { return nil }
        return SearchHit(
            category: category,
            serverId: id,
            title: title,
            snippet: snippet ?? "",
            createdAt: createdAt,
            documentType: type,
            version: version,
            author: author,
            commentCount: comments,
            proposalStatus: status.flatMap { ProposalStatus(rawValue: $0) },
            likeCount: likes,
            department: dept,
            pmName: pm,
            progress: progress
        )
    }
}

private extension KeyedDecodingContainer where Key == SearchItemDTO.CodingKeys {
    func decodeLossyString(forKey key: Key) throws -> String? {
        if let text = try? decodeIfPresent(String.self, forKey: key) { return text }
        if let number = try? decodeIfPresent(Double.self, forKey: key) {
            return number == number.rounded() ? String(Int(number)) : String(number)
        }
        return nil
    }

    func decodeLossyInt(forKey key: Key) -> Int? {
        if let number = try? decodeIfPresent(Int.self, forKey: key) { return number }
        if let number = try? decodeIfPresent(Double.self, forKey: key) { return Int(number.rounded()) }
        if let text = try? decodeIfPresent(String.self, forKey: key) { return Int(text) }
        return nil
    }
}
