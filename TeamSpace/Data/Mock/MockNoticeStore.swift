import Foundation

/// 10-5 ~ 10-7 공지 가짜 저장소 — 41 · 42 · 43 은 02-1 홈 공지와 같은 ID 예요.
/// 예약 게시는 시각이 지나야 목록에 보이고, 임시 저장은 목록에 보이지 않아요.
final class MockNoticeStore: @unchecked Sendable {
    private struct Record {
        var summary: NoticeSummaryDTO
        let authorName: String
        let authorRole: String
        let body: String
        var viewCount: Int
        let linkedDocument: NoticeDetailDTO.LinkedDocument?
        let isDraft: Bool
    }

    private let lock = NSLock()
    private var records: [Record] = []
    private var acknowledgedAt: [Int: Date] = [:]

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
                   authorName: "안율", authorRole: "NativeOps", body: Self.meetingBody, viewCount: 64,
                   linkedDocument: nil, isDraft: false),
            Record(summary: summary(41, .finance, "10월 프로젝트 정산 기준 안내",
                                    "수주 금액은 운영 · 적립 · 배당 풀로 나눠 관리해요.", at(1), important: true),
                   authorName: "김민준", authorRole: "FA", body: Self.settlementBody, viewCount: 52,
                   linkedDocument: .init(id: 2, title: "외주 수금 및 풀 배분 기준", category: "FINANCE"), isDraft: false),
            Record(summary: summary(42, .rule, "외주 프로젝트 착수 전 체크리스트",
                                    "착수 전에 계약 · 인력 · 일정 확인 항목을 점검해요.", at(3)),
                   authorName: "안율", authorRole: "NativeOps",
                   body: "외주 프로젝트를 시작하기 전에 계약서, 인력 배정, 일정 공유를 꼭 확인해 주세요.", viewCount: 38,
                   linkedDocument: .init(id: 1, title: "프로젝트 운영 원칙", category: "RULE"), isDraft: false),
            Record(summary: summary(43, .notice, "NativeLab 계약서 작성 가이드",
                                    "NativeLab 외주 계약서를 쓸 때 확인할 항목이에요.", at(8)),
                   authorName: "김민준", authorRole: "FA", body: "계약서 양식은 문서함 템플릿을 사용해 주세요.", viewCount: 27,
                   linkedDocument: nil, isDraft: false),
            Record(summary: summary(5, .notice, "추석 연휴 운영 안내", "연휴 기간에는 결재 처리가 늦어질 수 있어요.", at(20)),
                   authorName: "안율", authorRole: "NativeOps", body: "연휴 기간에는 결재 처리가 늦어질 수 있어요. 급한 건은 미리 올려 주세요.",
                   viewCount: 71, linkedDocument: nil, isDraft: false)
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

    func summaries(ids: [Int]) -> [NoticeSummaryDTO] {
        lock.lock()
        defer { lock.unlock() }
        let all = visible()
        return ids.compactMap { id in all.first { $0.summary.id == id }?.summary }
    }

    func search(_ keyword: String) -> [NoticeSummaryDTO] {
        lock.lock()
        defer { lock.unlock() }
        guard !keyword.isEmpty else { return [] }
        return visible().map(\.summary).filter {
            $0.title.localizedCaseInsensitiveContains(keyword) || $0.summary?.localizedCaseInsensitiveContains(keyword) == true
        }
    }

    /// GET /notices
    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(NoticeListResponseDTO(list: visible().map(\.summary)))
    }

    /// GET /notices/{id} — 볼 때마다 조회 수 +1
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = records.firstIndex(where: { $0.summary.id == id && !$0.isDraft }) else { return nil }
        records[index].viewCount += 1
        let record = records[index]
        return envelope(NoticeDetailDTO(
            notice: record.summary, authorName: record.authorName, authorRole: record.authorRole, body: record.body,
            viewCount: record.viewCount, linkedDocument: record.linkedDocument, acknowledgedAt: acknowledgedAt[id]
        ))
    }

    /// POST /notices/{id}/acknowledge
    func acknowledge(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard records.contains(where: { $0.summary.id == id }) else { return nil }
        let date = acknowledgedAt[id] ?? Date()
        acknowledgedAt[id] = date
        return envelope(NoticeAcknowledgeResponseDTO(acknowledgedAt: date))
    }

    /// POST /notices — 예약이면 그 시각을 게시 시각으로 둬요.
    func publish(_ request: NoticePublishRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        let id = (records.map(\.summary.id).max() ?? 0) + 1
        let summary = NoticeSummaryDTO(
            id: id, category: .notice, title: request.title,
            summary: request.body.split(separator: "\n").first.map(String.init),
            updatedAt: request.scheduledAt ?? Date(), isPinned: request.isPinned, isImportant: request.isImportant
        )
        records.append(Record(
            summary: summary, authorName: "김민준", authorRole: "FA", body: request.body, viewCount: 0,
            linkedDocument: nil, isDraft: request.isDraft
        ))
        return envelope(summary)
    }

    private func envelope<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
