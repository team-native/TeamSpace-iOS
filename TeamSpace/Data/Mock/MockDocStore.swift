import Foundation

/// Mock 문서함 · 규칙 — 서버 `/docs` 형식 (TeamSpace-backend `documents.py`, 프런트 `Doc`)
/// 날짜는 오늘 기준 "yyyy.MM.dd" 문자열이라 언제 실행해도 최근 문서처럼 보여요.
final class MockDocStore: @unchecked Sendable {
    /// Figma 06-2 최근 검색어 (처음 실행할 때만)
    static let recentKeywords = ["수금", "품의서", "회의"]

    struct Doc {
        let slug: String
        let type: String
        var category: String
        var title: String
        var copy: String
        /// 며칠 전 수정
        var daysAgo: Int
        /// 며칠 전 시행 (음수면 앞으로)
        var effectiveDaysAgo: Int? = nil
        var version = "v1.0"
        var owner = "NativeOps · 안율"
        var revised = false
        /// POST /admin/docs 로 정한 시행일 "yyyy.MM.dd"
        var effectiveText: String? = nil
    }

    static let docs: [Doc] = [
        Doc(slug: "project-principles", type: "RULE", category: "운영 규칙", title: "Native 프로젝트 운영 원칙",
            copy: "아이디어 제안부터 출시까지의 기준", daysAgo: 4, effectiveDaysAgo: -5, version: "v1.3", revised: true),
        Doc(slug: "meeting-principles", type: "RULE", category: "운영 규칙", title: "회의와 의사결정 원칙",
            copy: "짧게 논의하고 명확하게 기록하기", daysAgo: 7, effectiveDaysAgo: 3, version: "v1.1"),
        Doc(slug: "outsourcing-pool", type: "FINANCE", category: "재무", title: "외주 수금 및 풀 배분 기준",
            copy: "운영풀 · 적립풀 · 배당풀 배분과 정산 방식을 정리해요", daysAgo: 10, owner: "FA · 양지우"),
        Doc(slug: "budget-request", type: "TEMPLATE", category: "템플릿", title: "예산 품의서",
            copy: "비용 승인 요청 전에 쓰는 기본 양식이에요.\n작성하면 바로 결재로 이어져요.", daysAgo: 15),
        Doc(slug: "outsourcing-guide", type: "GUIDE", category: "가이드", title: "외주 프로젝트 진행 가이드",
            copy: "문의 접수부터 납품 후 정산 요청 순서", daysAgo: 17),
        Doc(slug: "operating-expenses", type: "FINANCE", category: "재무", title: "운영비 사용 기준",
            copy: "비품 · 구독 · 행사비 사용 범위", daysAgo: 27, owner: "FA · 양지우"),
        Doc(slug: "staffing-request", type: "TEMPLATE", category: "템플릿", title: "프로젝트 인력 지원 요청서",
            copy: "프로젝트에 필요한 직군과 인원을 요청하는 양식이에요.", daysAgo: 30),
        Doc(slug: "onboarding", type: "RULE", category: "팀 규칙", title: "신규 멤버 온보딩 규칙",
            copy: "합류 첫 2주 동안 하는 일", daysAgo: 33),
        Doc(slug: "design-dev-guide", type: "GUIDE", category: "가이드", title: "디자인 · 개발 협업 가이드",
            copy: "핸드오프와 리뷰 순서", daysAgo: 34),
        Doc(slug: "settlement-request", type: "TEMPLATE", category: "템플릿", title: "정산 요청서",
            copy: "프로젝트 종료 후 정산을 요청하는 양식", daysAgo: 35),
        Doc(slug: "card-receipts", type: "FINANCE", category: "재무", title: "법인카드 · 영수증 처리 기준",
            copy: "증빙 제출과 마감 일정", daysAgo: 40, owner: "FA · 양지우"),
        Doc(slug: "security-accounts", type: "RULE", category: "운영 규칙", title: "보안 · 계정 관리 규칙",
            copy: "공용 계정과 권한 관리 방법", daysAgo: 45)
    ]

    private let lock = NSLock()
    private let now: Date
    private var readCount: [String: Int] = [:]
    /// POST /admin/docs 로 바뀐 문서 · 본문 · 변경 내역
    private var docs: [Doc] = MockDocStore.docs
    private var savedSections: [String: [[String: Any]]] = [:]
    private var savedHistory: [String: [[String: Any]]] = [:]

    init(now: Date = Date()) {
        self.now = now
    }

    private func current() -> [Doc] {
        lock.lock()
        defer { lock.unlock() }
        return docs
    }

    /// POST /admin/docs — 같은 slug 면 개정(버전 +0.1, 변경 내역 추가), 없으면 v1.0 으로 등록
    func save(_ request: ServerDocWriteRequestDTO, who: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let sections: [[String: Any]] = request.sections.map { section in
            var item: [String: Any] = ["title": section.title, "lines": section.lines.map { ["text": $0.text] }]
            if section.revised { item["revised"] = true }
            return item
        }
        if let index = docs.firstIndex(where: { $0.slug == request.slug }) {
            let old = docs[index]
            let history = savedHistory[request.slug] ?? historyItems(old)
            var doc = old
            doc.title = request.title
            doc.copy = request.copy
            doc.category = request.category
            doc.daysAgo = 0
            doc.version = Self.nextVersion(old.version)
            doc.revised = true
            doc.owner = who
            doc.effectiveText = request.effective
            docs.remove(at: index)
            docs.insert(doc, at: 0)
            savedSections[request.slug] = sections
            savedHistory[request.slug] = [["ver": doc.version, "date": day(0), "who": who, "note": request.note]] + history
            return json(["slug": request.slug, "version": doc.version, "revisionId": history.count + 1])
        }
        var doc = Doc(slug: request.slug, type: request.type, category: request.category, title: request.title,
                      copy: request.copy, daysAgo: 0, owner: who)
        doc.effectiveText = request.effective
        docs.insert(doc, at: 0)
        savedSections[request.slug] = sections
        savedHistory[request.slug] = [["ver": "v1.0", "date": day(0), "who": who, "note": request.note]]
        return json(["slug": request.slug, "id": docs.count])
    }

    /// 서버 `_next_version` — "v1.3" → "v1.4"
    static func nextVersion(_ version: String) -> String {
        let parts = version.dropFirst().split(separator: ".")
        guard parts.count == 2, let major = Int(parts[0]), let minor = Int(parts[1]) else { return "v1.1" }
        return "v\(major).\(minor + 1)"
    }

    /// GET /docs?q&category&type&cursor&limit — 최근 수정 순
    func listJSON(query: [String: String]) -> String {
        var matched = current()
        if let q = query["q"]?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            matched = matched.filter { $0.title.localizedCaseInsensitiveContains(q) || $0.copy.localizedCaseInsensitiveContains(q) }
        }
        if let type = query["type"] { matched = matched.filter { $0.type == type } }
        if let category = query["category"] { matched = matched.filter { $0.category == category } }
        let offset = query["cursor"].flatMap(Int.init) ?? 0
        let limit = query["limit"].flatMap(Int.init) ?? 20
        let page = Array(matched.dropFirst(offset).prefix(limit))
        let next: Any = offset + limit < matched.count ? String(offset + limit) : NSNull()
        return json(["items": page.map(summary), "nextCursor": next])
    }

    /// GET /docs/{slug}
    func detailJSON(slug: String) -> String? {
        guard let doc = current().first(where: { $0.slug == slug }) else { return nil }
        var body = summary(doc)
        if doc.type == "TEMPLATE" {
            body["fields"] = Self.fields(slug).map { [$0.0, $0.1] }
        } else {
            lock.lock()
            let saved = savedSections[slug]
            lock.unlock()
            body["sections"] = saved ?? sections(doc)
        }
        return json(body)
    }

    /// GET /docs/{slug}/history
    func historyJSON(slug: String) -> String? {
        guard let doc = current().first(where: { $0.slug == slug }) else { return nil }
        lock.lock()
        let saved = savedHistory[slug]
        lock.unlock()
        return json(["items": saved ?? historyItems(doc), "nextCursor": NSNull()])
    }

    private func historyItems(_ doc: Doc) -> [[String: Any]] {
        let items: [[String: Any]]
        switch doc.slug {
        case "project-principles":
            items = [
                ["ver": "v1.3", "date": day(doc.daysAgo), "who": "안율", "note": "제2조 검토 기한 3주 → 2주"],
                ["ver": "v1.2", "date": day(doc.daysAgo + 70), "who": "양지우", "note": "제3조 인력 요청을 결재로 일원화"],
                ["ver": "v1.0", "date": day(doc.daysAgo + 210), "who": "김민준", "note": "최초 제정"]
            ]
        case _ where doc.version != "v1.0":
            items = [
                ["ver": doc.version, "date": day(doc.daysAgo), "who": "안율", "note": "제2조 적용 범위 정리"],
                ["ver": "v1.0", "date": day(doc.daysAgo + 60), "who": "김민준", "note": "최초 제정"]
            ]
        default:
            items = [["ver": "v1.0", "date": day(doc.daysAgo), "who": "김민준", "note": "최초 제정"]]
        }
        return items
    }

    /// POST /docs/{slug}/read
    func read(slug: String) -> String? {
        guard current().contains(where: { $0.slug == slug }) else { return nil }
        lock.lock()
        defer { lock.unlock() }
        readCount[slug, default: 0] += 1
        return json(["slug": slug, "read": true, "confirmed": readCount[slug] ?? 1])
    }

    private func summary(_ doc: Doc) -> [String: Any] {
        [
            "slug": doc.slug, "type": doc.type, "category": doc.category, "title": doc.title, "copy": doc.copy,
            "date": day(doc.daysAgo), "version": doc.version, "effective": doc.effectiveText ?? day(doc.effectiveDaysAgo ?? doc.daysAgo),
            "owner": doc.owner, "revised": doc.revised
        ]
    }

    private func sections(_ doc: Doc) -> [[String: Any]] {
        guard doc.slug == "project-principles" else {
            return [
                ["title": "제1조 목적", "lines": [["text": "\(doc.title)은 팀이 같은 기준으로 일하기 위해 만들어졌어요."]]],
                ["title": "제2조 적용 범위", "lines": [["text": "Native 모든 구성원과 진행 중인 프로젝트에 적용돼요."]]],
                ["title": "제3조 문의", "lines": [["text": "궁금한 점은 담당자에게 문의해 주세요."]]]
            ]
        }
        return [
            ["title": "제1조 목적", "lines": [[
                "text": "이 원칙은 Native에서 진행하는 모든 프로젝트가 같은 기준으로 시작하고, 같은 방식으로 마무리되도록 하기 위해 만들어졌어요."
            ]]],
            ["title": "제2조 아이디어 제안", "revised": true, "lines": [[
                "text": "누구나 제안서를 올릴 수 있어요. 제안서는 문서함의 템플릿으로 작성하고, PO가 ",
                "was": "3주", "now": "2주", "after": " 안에 진행 여부를 결정해요."
            ]]],
            ["title": "제3조 팀 구성", "lines": [[
                "text": "PM은 프로젝트 시작 전 필요한 직군과 인원을 결재로 요청해요. 인력 지원 요청은 PMO가 1차로 검토해요."
            ]]],
            ["title": "제4조 출시와 회고", "lines": [["text": "출시 후 2주 안에 회고를 진행하고 결과를 문서함에 남겨요."]]]
        ]
    }

    /// 템플릿 항목 — 프런트처럼 [label, hint] 쌍
    static func fields(_ slug: String) -> [(String, String)] {
        switch slug {
        case "budget-request":
            return [("비용 유형", "물품 · 구독 · 외부 비용"), ("요청 금액과 사용일", "부가세 포함 금액"),
                    ("요청 사유", "목적과 기대 효과"), ("첨부", "견적서 · 영수증")]
        case "staffing-request":
            return [("프로젝트", "지원이 필요한 프로젝트"), ("직군과 인원", "필요한 역할과 인원 수"), ("지원 기간과 사유", "진행 일정과 요청 목적")]
        default:
            return [("문서 제목", "정산할 프로젝트와 요청 제목"), ("정산 내용", "금액 · 사용 내역 · 정산 사유"), ("첨부", "영수증 · 정산 증빙")]
        }
    }

    /// 서울 기준 "yyyy.MM.dd"
    private func day(_ daysAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: now.addingTimeInterval(-Double(daysAgo) * 86_400))
    }

    private func json(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
}
