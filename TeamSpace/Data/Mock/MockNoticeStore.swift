import Foundation

/// 10-5 ~ 10-7 공지 가짜 저장소 — 41 · 42 · 43 은 02-1 홈 공지와 같은 ID 예요.
/// 예약 게시는 시각이 지나야 목록에 보이고, 임시 저장은 목록에 보이지 않아요.
final class MockNoticeStore: @unchecked Sendable {
    private struct Record {
        var summary: NoticeSummaryDTO
        let authorName: String
        var body: String
        let isDraft: Bool
    }

    /// 목 서버 기준 전체 인원 (서버 `total`)
    static let memberCount = 24

    private let lock = NSLock()
    private var records: [Record] = []
    private var confirmedIds: Set<Int> = []
    /// 테스트에서 마지막 게시 요청을 확인할 때
    private(set) var lastCreateRequest: ServerNoticeCreateRequestDTO?
    private(set) var lastPatchRequest: ServerNoticePatchRequestDTO?

    init(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        func at(_ daysAgo: Double) -> Date { today.addingTimeInterval(-daysAgo * 86_400 + 10 * 3_600) }
        func summary(_ id: Int, _ category: NoticeCategory, _ title: String, _ summary: String, _ date: Date,
                     pinned: Bool = false, important: Bool = false) -> NoticeSummaryDTO {
            NoticeSummaryDTO(id: id, category: category, title: title, summary: summary, updatedAt: date,
                             isPinned: pinned, isImportant: important)
        }
        records = [
            Record(summary: summary(1, .notice, "10월 정기 회의는 4층 홈베이스에서 진행해요",
                                    "이번 달 Native 정기 회의 장소와 시간을 안내해요.", at(17), pinned: true, important: true),
                   authorName: "안율", body: Self.meetingBody, isDraft: false),
            Record(summary: summary(41, .finance, "10월 프로젝트 정산 기준 안내",
                                    "수주 금액은 운영 · 적립 · 배당 풀로 나눠 관리해요.", at(1), important: true),
                   authorName: "김민준", body: Self.settlementBody, isDraft: false),
            Record(summary: summary(42, .rule, "외주 프로젝트 착수 전 체크리스트",
                                    "착수 전에 계약 · 인력 · 일정 확인 항목을 점검해요.", at(3)),
                   authorName: "안율",
                   body: "외주 프로젝트를 시작하기 전에 계약서, 인력 배정, 일정 공유를 꼭 확인해 주세요.", isDraft: false),
            Record(summary: summary(43, .notice, "NativeLab 계약서 작성 가이드",
                                    "NativeLab 외주 계약서를 쓸 때 확인할 항목이에요.", at(8)),
                   authorName: "김민준", body: "계약서 양식은 문서함 템플릿을 사용해 주세요.", isDraft: false),
            Record(summary: summary(5, .notice, "추석 연휴 운영 안내", "연휴 기간에는 결재 처리가 늦어질 수 있어요.", at(20)),
                   authorName: "안율", body: "연휴 기간에는 결재 처리가 늦어질 수 있어요. 급한 건은 미리 올려 주세요.", isDraft: false)
        ]
    }

    private static let meetingBody = """
    이번 달 Native 정기 회의는 4층 홈베이스에서 진행해요.

    • 일시: 2026.10.24 14:00–16:00
    • 대상: Native 전체 구성원
    • 장소: 4층 홈베이스

    프로젝트별 진행 상황과 11월 활동 계획을 나눌 예정이에요.
    """

    private static let settlementBody = """
    이번 달부터 외주 프로젝트 정산은 입금 확인 후 3영업일 안에 진행돼요.

    • 운영풀 40% · 적립풀 30% · 배당풀 30%로 자동 배분해요.
    • 배당풀은 프로젝트 기여도 시트를 기준으로 나눠요.
    • 기여도 시트는 PM이 프로젝트 종료 후 1주 안에 제출해요.
    """

    /// 게시된 공지 (예약 시각이 지난 것 · 임시 저장 제외)
    private func visible(now: Date = Date()) -> [Record] {
        records.filter { !$0.isDraft && $0.summary.updatedAt <= now }
    }

    /// GET /notices — 서버(develop) 형식 `{items, nextCursor}`, 고정 → 최신순, 커서 `o:N`
    /// `ids` 를 주면 그 순서대로 고정 공지로 돌려줘요. (게시판 고정 공지)
    func serverItemsJSON(ids: [Int]? = nil, keyword: String? = nil, cursor: String? = nil, limit: Int = 20) -> String {
        lock.lock()
        defer { lock.unlock() }
        var list = visible().sorted { left, right in
            if left.summary.isPinned != right.summary.isPinned { return left.summary.isPinned }
            return left.summary.updatedAt > right.summary.updatedAt
        }
        if let ids { list = ids.compactMap { id in list.first { $0.summary.id == id } } }
        if let keyword = keyword?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
            list = list.filter {
                $0.summary.title.localizedCaseInsensitiveContains(keyword) || $0.body.localizedCaseInsensitiveContains(keyword)
            }
        }
        let start = cursor.flatMap { $0.hasPrefix("o:") ? Int($0.dropFirst(2)) : nil } ?? 0
        let page = Array(list.dropFirst(start).prefix(limit))
        let next: Any = start + limit < list.count ? "o:\(start + limit)" : NSNull()
        let rows = page.map { serverFields($0, pinned: ids != nil || $0.summary.isPinned) }
        return json(["items": rows, "nextCursor": next])
    }

    /// GET /notices/{id} — 서버 형식 (조회 수 · 작성자 역할 · 연결 문서 없음)
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = records.first(where: { $0.summary.id == id && !$0.isDraft }) else { return nil }
        return json(serverFields(record, pinned: record.summary.isPinned))
    }

    /// POST /notices/{id}/confirm — `{id, confirmedByMe, confirmed}`
    func confirm(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard records.contains(where: { $0.summary.id == id && !$0.isDraft }) else { return nil }
        confirmedIds.insert(id)
        return json(["id": String(id), "confirmedByMe": true, "confirmed": confirmedCount(id)])
    }

    private func confirmedCount(_ id: Int) -> Int {
        confirmedIds.contains(id) ? 1 : 0
    }

    private func serverFields(_ record: Record, pinned: Bool) -> [String: Any] {
        var fields: [String: Any] = [:]
        fields["id"] = String(record.summary.id)
        fields["kind"] = Self.serverKind(record.summary.category)
        fields["title"] = record.summary.title
        fields["body"] = record.body
        fields["author"] = record.authorName
        fields["createdAt"] = MockBoardStore.pythonISO(record.summary.updatedAt)
        fields["pinned"] = pinned
        fields["mustRead"] = record.summary.isImportant
        fields["confirmed"] = confirmedCount(record.summary.id)
        fields["total"] = Self.memberCount
        fields["confirmedByMe"] = confirmedIds.contains(record.summary.id)
        return fields
    }

    private static func serverKind(_ category: NoticeCategory) -> String {
        switch category {
        case .finance: return "재무"
        case .rule: return "규칙"
        case .notice, .unknown: return "공지"
        }
    }

    private func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    /// PATCH /admin/notices/{id} — 제목 · 본문 · 고정 · 필독만 바꿔요. 없으면 nil
    func update(id: Int, request: ServerNoticePatchRequestDTO) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.summary.id == id }) else { return nil }
        let old = records[index].summary
        records[index].summary = NoticeSummaryDTO(
            id: id, category: old.category, title: request.title,
            summary: request.body.split(separator: "\n").first.map(String.init),
            updatedAt: old.updatedAt, isPinned: request.pinned, isImportant: request.mustRead
        )
        records[index].body = request.body
        lastPatchRequest = request
        return json(serverFields(records[index], pinned: request.pinned))
    }

    /// POST /admin/notices — `{id}`. 예약이면 그 시각을 게시 시각으로, 임시 저장은 목록에서 빼요.
    /// (서버 develop 은 status · publishAt 을 저장만 해요 — 백엔드 협의안대로 흉내 내요)
    func publish(_ request: ServerNoticeCreateRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        let id = (records.map(\.summary.id).max() ?? 0) + 1
        let summary = NoticeSummaryDTO(
            id: id, category: NoticeCategory(serverKind: request.kind), title: request.title,
            summary: request.body.split(separator: "\n").first.map(String.init),
            updatedAt: request.publishAt ?? Date(), isPinned: request.pinned, isImportant: request.mustRead
        )
        records.append(Record(summary: summary, authorName: "김민준", body: request.body, isDraft: request.status == .draft))
        lastCreateRequest = request
        return json(["id": String(id)])
    }
}
