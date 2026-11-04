import Foundation

/// GET /docs 한 항목 · GET /docs/{slug} 본문 (TeamSpace-backend `documents.py`)
/// 서버는 프런트 `Doc` 을 그대로 저장해서 날짜가 "2026.07.18" 같은 표시용 문자열이에요.
struct ServerDocDTO: Decodable {
    let slug: String
    let category: String?
    let type: String?
    let title: String
    let copy: String?
    let date: String?
    let version: String?
    let effective: String?
    let owner: String?
    let revised: Bool
    let sections: [ServerDocSectionDTO]
    let fields: [TemplateField]
    /// 템플릿 원본 파일 — 서버가 `fileId` 가 있으면 `downloadUrl: "/uploads/{id}"` 도 줘요.
    let fileId: String?
    let downloadUrl: String?
    let fileName: String?
    let fileSize: Int?

    private enum CodingKeys: String, CodingKey {
        case slug, category, type, title, copy, date, version, effective, owner, revised, sections, fields
        case fileId, downloadUrl, fileName, filename, fileSize, size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        copy = try? container.decodeIfPresent(String.self, forKey: .copy)
        date = try? container.decodeIfPresent(String.self, forKey: .date)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        effective = try? container.decodeIfPresent(String.self, forKey: .effective)
        owner = try? container.decodeIfPresent(String.self, forKey: .owner)
        revised = (try? container.decodeIfPresent(Bool.self, forKey: .revised)) ?? false
        sections = (try? container.decodeIfPresent([ServerDocSectionDTO].self, forKey: .sections)) ?? []
        fields = ((try? container.decodeIfPresent([ServerTemplateFieldDTO].self, forKey: .fields)) ?? []).compactMap(\.field)
        fileId = (try? container.decodeIfPresent(String.self, forKey: .fileId))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .fileId)).flatMap { $0.map(String.init) }
        downloadUrl = try? container.decodeIfPresent(String.self, forKey: .downloadUrl)
        fileName = (try? container.decodeIfPresent(String.self, forKey: .fileName))
            ?? (try? container.decodeIfPresent(String.self, forKey: .filename))
        fileSize = (try? container.decodeIfPresent(Int.self, forKey: .fileSize))
            ?? (try? container.decodeIfPresent(Int.self, forKey: .size))
    }

    /// 원본 파일 — 이름이 없으면 템플릿 제목으로 받아요.
    var templateFile: FileAttachment? {
        guard let id = FileAttachment.uploadId(id: fileId, url: downloadUrl) else { return nil }
        let name = fileName.flatMap { $0.isEmpty ? nil : $0 } ?? title
        return FileAttachment(name: name, sizeText: fileSize.map(FileAttachment.sizeText) ?? "원본 양식 파일", fileId: id)
    }

    var libraryCategory: LibraryCategory {
        LibraryCategory(rawValue: (type ?? "").uppercased()) ?? .unknown
    }

    var updatedAt: Date { date.flatMap(Self.day) ?? .distantPast }
    var effectiveAt: Date { effective.flatMap(Self.day) ?? updatedAt }

    /// "2026.07.18" · "2026-07-18" · ISO 날짜를 모두 읽어요. (서울 기준 그날 0시)
    static func day(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let date = ServerTodoDTO.date(fromDay: trimmed.replacingOccurrences(of: ".", with: "-")) { return date }
        return ServerDate.parse(trimmed)
    }

    func toLibraryDocument(excerpt: String? = nil) -> LibraryDocument {
        LibraryDocument(
            id: slug, category: libraryCategory, title: title, summary: copy ?? "", excerpt: excerpt, updatedAt: updatedAt
        )
    }

    /// 운영 규칙 · 재무 문서만 09 규칙으로 보여줘요.
    var isRule: Bool { libraryCategory == .rule || libraryCategory == .finance }

    /// "Leader · 김준표" → 담당 "Leader"
    var department: String {
        let text = owner ?? ""
        return text.components(separatedBy: " · ").first?.trimmingCharacters(in: .whitespaces) ?? text
    }

    var ruleCategory: RuleCategory {
        if libraryCategory == .finance { return .finance }
        let text = category ?? ""
        if text.contains("재무") || text.contains("예산") { return .finance }
        if text.contains("프로젝트") { return .project }
        if text.contains("인사") || text.contains("조직") || text.contains("온보딩") || text.contains("팀") { return .people }
        return .operation
    }

    func toRuleSummary(isAcknowledged: Bool, revisionCount: Int = 0, now: Date = Date()) -> RuleSummary {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let today = calendar.startOfDay(for: now)
        return RuleSummary(
            id: slug,
            title: title,
            category: ruleCategory,
            department: department,
            version: version ?? "",
            status: effectiveAt > today ? .scheduled : .active,
            effectiveAt: effectiveAt,
            revisedAt: updatedAt,
            isImportant: revised,
            isAcknowledged: isAcknowledged,
            changeSummary: changeSummary,
            revisionCount: revisionCount
        )
    }

    /// 바뀐 문장이 있으면 "3주 → 2주"
    var changeSummary: String? {
        sections.lazy.compactMap(\.highlight).first
    }

    /// "제2조 아이디어 제안" → 2번 조항. 번호가 없으면 순서대로 매겨요.
    func articles() -> [RuleArticle] {
        sections.enumerated().map { index, section in section.toArticle(fallbackNumber: index + 1) }
    }

    func toTemplate() -> LibraryTemplate {
        LibraryTemplate(
            id: slug,
            title: title,
            description: copy ?? "",
            fields: fields,
            monthlyUsageCount: 0,
            formKind: TemplateFormKind(title: title),
            file: templateFile
        )
    }
}

/// 문서 본문 한 단락 — 프런트 `{ title: "제3조 배분 비율", revised?, lines: [{ text, was?, now?, after? }] }`
struct ServerDocSectionDTO: Decodable {
    let title: String
    let revised: Bool
    let lines: [ServerDocLineDTO]

    private enum CodingKeys: String, CodingKey { case title, revised, lines }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        revised = (try? container.decodeIfPresent(Bool.self, forKey: .revised)) ?? false
        lines = (try? container.decodeIfPresent([ServerDocLineDTO].self, forKey: .lines)) ?? []
    }

    var body: String { lines.map(\.current).joined(separator: "\n") }
    var previousBody: String { lines.map(\.previous).joined(separator: "\n") }
    var highlight: String? { lines.lazy.compactMap(\.highlight).first }

    func toArticle(fallbackNumber: Int) -> RuleArticle {
        let (number, name) = Self.split(title)
        let changed = highlight
        return RuleArticle(
            number: number ?? fallbackNumber,
            title: name,
            body: body,
            isRevised: revised || changed != nil,
            changeNote: changed,
            comparison: changed.map {
                RuleArticleComparison(label: "개정", previousBody: previousBody, highlight: $0, reason: nil)
            }
        )
    }

    /// "제2조 아이디어 제안" → (2, "아이디어 제안")
    static func split(_ title: String) -> (Int?, String) {
        guard
            title.hasPrefix("제"),
            let end = title.range(of: "조"),
            let number = Int(title[title.index(after: title.startIndex)..<end.lowerBound])
        else { return (nil, title) }
        return (number, title[end.upperBound...].trimmingCharacters(in: .whitespaces))
    }
}

struct ServerDocLineDTO: Decodable {
    let text: String
    let was: String?
    let now: String?
    let after: String?

    private enum CodingKeys: String, CodingKey { case text, was, now, after }

    init(from decoder: Decoder) throws {
        if let plain = try? decoder.singleValueContainer().decode(String.self) {
            text = plain
            was = nil
            now = nil
            after = nil
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = (try? container.decodeIfPresent(String.self, forKey: .text)) ?? ""
        was = try? container.decodeIfPresent(String.self, forKey: .was)
        now = try? container.decodeIfPresent(String.self, forKey: .now)
        after = try? container.decodeIfPresent(String.self, forKey: .after)
    }

    var current: String { text + (now ?? "") + (after ?? "") }
    var previous: String { text + (was ?? now ?? "") + (after ?? "") }

    var highlight: String? {
        guard let was, let now, was != now else { return nil }
        return "\(was) → \(now)"
    }
}

/// 템플릿 항목 — 프런트는 `[label, hint]` 쌍, 객체로 오면 `{label|title, hint|subtitle}`
private struct ServerTemplateFieldDTO: Decodable {
    let field: TemplateField?

    private enum CodingKeys: String, CodingKey { case label, title, hint, subtitle }

    init(from decoder: Decoder) throws {
        if let pair = try? decoder.singleValueContainer().decode([String].self) {
            field = pair.first.map { TemplateField(title: $0, subtitle: pair.count > 1 ? pair[1] : "") }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = (try? container.decodeIfPresent(String.self, forKey: .label))
            ?? (try? container.decodeIfPresent(String.self, forKey: .title))
        let subtitle = (try? container.decodeIfPresent(String.self, forKey: .hint))
            ?? (try? container.decodeIfPresent(String.self, forKey: .subtitle))
        field = title.map { TemplateField(title: $0, subtitle: subtitle ?? "") }
    }
}

/// GET /docs/{slug}/history 한 항목
struct ServerDocHistoryDTO: Decodable {
    let ver: String?
    let date: String?
    let who: String?
    let note: String?

    func toEntity() -> RuleRevision? {
        guard let ver else { return nil }
        return RuleRevision(
            version: ver,
            revisedAt: date.flatMap(ServerDocDTO.day) ?? .distantPast,
            summary: note ?? "",
            department: "",
            author: who ?? ""
        )
    }
}

/// POST /docs/{slug}/read 응답
struct ServerDocReadDTO: Decodable {
    let slug: String
    let read: Bool
}

extension TemplateFormKind {
    /// 서버 템플릿에는 결재 양식 종류가 없어 제목으로 정해요.
    init(title: String) {
        if title.contains("인력") {
            self = .staffing
        } else if title.contains("정산") {
            self = .settlement
        } else if title.contains("품의") || title.contains("예산") || title.contains("구매") || title.contains("비용") {
            self = .expense
        } else {
            self = .unknown
        }
    }
}

/// 규칙 읽음 확인 — 서버에 다시 불러올 곳이 없어 기기에 시각을 저장해요.
final class RuleAcknowledgementStore: @unchecked Sendable {
    static let keyPrefix = "rule.acknowledged."
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func acknowledgedAt(_ slug: String) -> Date? {
        defaults.object(forKey: Self.keyPrefix + slug) as? Date
    }

    func save(_ date: Date, for slug: String) {
        defaults.set(date, forKey: Self.keyPrefix + slug)
    }

    func clear(_ slug: String) {
        defaults.removeObject(forKey: Self.keyPrefix + slug)
    }
}

/// POST /admin/docs 요청 — 같은 slug 가 있으면 개정, 없으면 등록이에요.
/// 조항은 `{ title: "제2조 아이디어 제안", revised, lines: [{ text }] }` (문단마다 한 줄)
struct ServerDocWriteRequestDTO: Codable, Equatable {
    struct Section: Codable, Equatable {
        struct Line: Codable, Equatable { let text: String }
        let title: String
        let revised: Bool
        let lines: [Line]
    }

    let slug: String
    let type: String
    let category: String
    let title: String
    let copy: String
    let effective: String
    let sections: [Section]
    let note: String
    let notify: Bool

    init(_ draft: RuleDraft, slug: String, calendar: Calendar = .current) {
        self.slug = slug
        type = "RULE"
        category = draft.categoryText
        title = draft.title
        copy = draft.summary
        let day = calendar.dateComponents([.year, .month, .day], from: draft.effectiveDate)
        effective = String(format: "%04d.%02d.%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
        sections = draft.articles.enumerated().map { index, article in
            Section(
                title: "제\(index + 1)조 \(article.title)",
                revised: draft.isRevision && article.isChanged,
                lines: article.body.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .map(Section.Line.init)
            )
        }
        note = draft.isRevision ? draft.note : "최초 등록"
        notify = draft.notifies
    }
}

/// POST /admin/docs 응답 — 등록 `{slug, id}` · 개정 `{slug, version, revisionId}`
struct ServerDocSavedDTO: Decodable {
    let slug: String
}
