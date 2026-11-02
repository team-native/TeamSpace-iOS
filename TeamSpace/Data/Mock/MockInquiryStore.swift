import Foundation

/// 11 문의 가짜 저장소 — Figma 11-1 수정본 · 11-4 · 11-7 예시 (날짜는 오늘 기준)
/// 42 번은 02 알림의 "내 문의에 답변이 도착했어요"와 같은 문의예요.
final class MockInquiryStore: @unchecked Sendable {
    private struct Record {
        var summary: InquirySummaryDTO
        var history: [InquiryHistoryDTO]
        var reference: InquiryReferenceDTO?
        /// 내가 보낸 문의 (11-1)
        var isMine = true
        /// 실명 문의의 작성자
        var authorName: String? = "옥물결"
        var assignee: String?
    }

    /// 11-5 · 11-6 — Mock 담당자는 NativeOps 소속이에요.
    static let managerDepartment: InquiryDepartment = .nativeOps
    /// 11-6 관련 규칙 제목 (09 규칙과 같은 ID)
    private static let ruleTitles: [Int: (title: String, summary: String)] = [
        1: ("프로젝트 운영 원칙", "아이디어 제안부터 출시까지의 기준"),
        5: ("회의와 의사결정 원칙", "우선순위, 진행 방법 등"),
        8: ("신규 멤버 온보딩 규칙", "합류 첫 2주 동안 하는 일"),
        12: ("보안 · 계정 관리 규칙", "공용 계정과 권한 관리 방법"),
        13: ("예산 신청·증빙 가이드", "예산 신청과 증빙 제출 방법")
    ]

    private let lock = NSLock()
    private var records: [Record] = []

    init(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        func at(_ daysAgo: Double, _ hour: Double) -> Date { today.addingTimeInterval(-daysAgo * 86_400 + hour * 3_600) }
        records = [
            Record(
                summary: InquirySummaryDTO(
                    id: 42, department: .nativeOps, title: "회의실 예약 기준을 정해 주세요",
                    body: "스터디와 프로젝트 회의가 같은 시간에 겹치는 일이 많아요. 어떤 회의를 먼저 잡을지 기준이 있으면 좋겠어요.",
                    isAnonymous: true, createdAt: at(13, 15.5), status: .answered,
                    reply: InquiryReplyDTO(
                        department: .nativeOps,
                        body: "좋은 의견 감사합니다. 다음 주부터 1회 최대 2시간, 프로젝트 회의 우선으로 운영할게요.\n\n"
                            + "겹치는 예약은 담당자가 조정하며, 변경 결과는 신청자에게 따로 안내해요. "
                            + "적용 일정과 세부 예외는 관련 운영 가이드에서 확인해 주세요.",
                        repliedAt: at(10, 14)
                    )
                ),
                history: [
                    InquiryHistoryDTO(status: .received, occurredAt: at(13, 15.5), note: "NativeOps에 전달"),
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(12, 10.33), note: "예약 현황과 운영 기준 확인", actor: "양지우"),
                    InquiryHistoryDTO(status: .answered, occurredAt: at(10, 14), note: "공식 답변 등록", actor: "양지우")
                ],
                reference: InquiryReferenceDTO(kind: .rule, id: 5, title: "회의와 의사결정 원칙", summary: "우선순위, 진행 방법 등"),
                assignee: "양지우"
            ),
            Record(
                summary: InquirySummaryDTO(
                    id: 43, department: .pmo, title: "프로젝트 회고 시간을 제안해요",
                    body: "프로젝트가 끝나면 회고 시간을 정기적으로 잡아 주시면 좋겠어요.",
                    isAnonymous: true, createdAt: at(11, 11), status: .reviewing, reply: nil
                ),
                history: [
                    InquiryHistoryDTO(status: .received, occurredAt: at(11, 11), note: "PMO에 전달"),
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(10, 9.5), note: "프로젝트 일정과 함께 검토")
                ],
                reference: nil
            ),
            Record(
                summary: InquirySummaryDTO(
                    id: 44, department: .fa, title: "정산 내역 안내를 개선해 주세요",
                    body: "정산 기준이 바뀔 때마다 어디서 확인해야 하는지 헷갈려요.",
                    isAnonymous: false, createdAt: at(9, 16), status: .received, reply: nil
                ),
                history: [InquiryHistoryDTO(status: .received, occurredAt: at(9, 16), note: "FA에 전달")],
                reference: nil
            ),
            Record(
                summary: InquirySummaryDTO(
                    id: 41, department: .nativeOps, title: "회의실을 앱에서 바로 예약할 수 있게 해 주세요",
                    body: "지금은 단톡방에서 회의실을 잡다 보니 겹치는 일이 많아요. 앱에서 시간대를 보고 바로 예약하면 좋겠어요.",
                    isAnonymous: true, createdAt: at(14, 15.5), status: .rejected,
                    reply: InquiryReplyDTO(
                        department: .nativeOps,
                        body: "회의실은 학교가 관리하는 시설이라 앱에서 직접 예약을 받을 수 없어요.\n\n"
                            + "대신 매주 월요일에 회의실 예약 현황을 공지로 올려 드릴게요. 다른 방법이 필요하면 아래에서 다시 문의해 주세요.",
                        repliedAt: at(11, 14)
                    )
                ),
                history: [
                    InquiryHistoryDTO(status: .received, occurredAt: at(14, 15.5), note: "NativeOps에 전달"),
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(13, 10.33), note: "학교 시설 이용 규정 확인", actor: "이시우"),
                    InquiryHistoryDTO(status: .rejected, occurredAt: at(11, 14), note: "반려 사유 등록", actor: "이시우")
                ],
                reference: InquiryReferenceDTO(kind: .notice, id: nil, title: "회의실 이용 안내", summary: "예약 현황 · 이용 시간 · 문의처"),
                assignee: "이시우"
            )
        ] + Self.inboxSeed(at: at)
    }

    /// 11-5 다른 구성원이 NativeOps 에 보낸 문의 (Figma 11-5 · 11-6)
    private static func inboxSeed(at: (Double, Double) -> Date) -> [Record] {
        [
            Record(
                summary: InquirySummaryDTO(
                    id: 51, department: .nativeOps, title: "신규 구성원 안내 자료를 제안해요",
                    body: "처음 합류했을 때 어디서 문서를 찾는지 알기 어려웠어요. 자주 쓰는 문서와 문의 경로를 한곳에 모아주시면 좋겠습니다.",
                    isAnonymous: true, createdAt: at(5, 16.33), status: .reviewing, reply: nil
                ),
                history: [
                    InquiryHistoryDTO(status: .received, occurredAt: at(5, 16.33), note: "NativeOps에 전달"),
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(4, 10), note: "자료 검토 시작", actor: "양지우")
                ],
                reference: nil, isMine: false, authorName: nil, assignee: "양지우"
            ),
            Record(
                summary: InquirySummaryDTO(
                    id: 52, department: .nativeOps, title: "활동 공간 이용 시간을 확인하고 싶어요",
                    body: "주말이나 저녁에도 활동 공간을 쓸 수 있는지 알고 싶어요.",
                    isAnonymous: true, createdAt: at(3, 14), status: .received, reply: nil
                ),
                history: [InquiryHistoryDTO(status: .received, occurredAt: at(3, 14), note: "NativeOps에 전달")],
                reference: nil, isMine: false, authorName: nil, assignee: nil
            ),
            Record(
                summary: InquirySummaryDTO(
                    id: 53, department: .nativeOps, title: "정기 회의 자료 공유 경로 문의",
                    body: "정기 회의 자료를 어디에 올리고 어디서 확인하면 되는지 궁금해요.",
                    isAnonymous: false, createdAt: at(2, 9.17), status: .received, reply: nil
                ),
                history: [InquiryHistoryDTO(status: .received, occurredAt: at(2, 9.17), note: "NativeOps에 전달")],
                reference: nil, isMine: false, authorName: "이시우", assignee: nil
            )
        ]
    }

    /// GET /inquiries — 서버 형식 `{items, nextCursor}`, id 큰 순, 커서는 마지막 항목 id
    func mineJSON(cursor: String? = nil, limit: Int = 20) -> String {
        lock.lock()
        defer { lock.unlock() }
        var mine = records.filter(\.isMine).sorted { $0.summary.id > $1.summary.id }
        if let cursor = cursor.flatMap(Int.init) { mine = mine.filter { $0.summary.id < cursor } }
        let page = Array(mine.prefix(limit))
        let next: Any = mine.count > limit ? String(page.last?.summary.id ?? 0) : NSNull()
        return json(["items": page.map(Self.serverFields), "nextCursor": next])
    }

    /// POST /inquiries — 접수 상태로 추가하고 `{id, status}` 를 돌려줘요.
    func submit(_ request: ServerInquiryCreateRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        let id = (records.map(\.summary.id).max() ?? 0) + 1
        let now = Date()
        let department = InquiryDepartment(serverValue: request.dept)
        let summary = InquirySummaryDTO(
            id: id, department: department, title: request.title, body: request.body,
            isAnonymous: request.anonymous, createdAt: now, status: .received, reply: nil
        )
        records.append(Record(
            summary: summary,
            history: [InquiryHistoryDTO(status: .received, occurredAt: now, note: "\(Self.departmentName(department))에 전달")],
            reference: nil,
            authorName: request.anonymous ? nil : "옥물결"
        ))
        return json(["id": String(id), "status": "접수"])
    }

    /// 서버가 저장하는 문의 payload 모양 — steps 는 [접수, 검토, 답변] 시각 (안 된 단계는 "")
    private static func serverFields(_ record: Record) -> [String: Any] {
        let summary = record.summary
        func stepAt(_ statuses: [InquiryStatus]) -> String {
            record.history.first { statuses.contains($0.status) }.map { MockBoardStore.pythonISO($0.occurredAt) } ?? ""
        }
        var fields: [String: Any] = [:]
        fields["id"] = String(summary.id)
        fields["type"] = "문의"
        fields["dept"] = summary.department.serverValue
        fields["title"] = summary.title
        fields["body"] = summary.body
        fields["anonymous"] = summary.isAnonymous
        fields["status"] = summary.status.serverValue
        fields["steps"] = [stepAt([.received]), stepAt([.reviewing]), stepAt([.answered, .rejected])]
        fields["replies"] = [Any]()
        fields["author"] = summary.isAnonymous ? "익명" : record.authorName ?? "알 수 없음"
        if let assignee = record.assignee { fields["assignee"] = assignee }
        if let reference = record.reference {
            var item: [String: Any] = ["kind": reference.kind.rawValue, "title": reference.title, "summary": reference.summary]
            if let id = reference.id { item["id"] = id }
            fields["reference"] = item
        }
        if let reply = summary.reply {
            let actor = record.history.last { $0.status == summary.status }?.actor
            fields["answer"] = ["who": actor ?? departmentName(reply.department), "at": MockBoardStore.pythonISO(reply.repliedAt), "text": reply.body]
        } else {
            fields["answer"] = NSNull()
        }
        return fields
    }

    private func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    /// GET /admin/inquiries — 담당 부서(NativeOps) 문의, id 큰 순, 커서는 마지막 항목 id
    func adminJSON(status: String? = nil, cursor: String? = nil, limit: Int = 30) -> String {
        lock.lock()
        defer { lock.unlock() }
        var list = records.filter { $0.summary.department == Self.managerDepartment }.sorted { $0.summary.id > $1.summary.id }
        if let status { list = list.filter { $0.summary.status.serverValue == status } }
        if let cursor = cursor.flatMap(Int.init) { list = list.filter { $0.summary.id < cursor } }
        let page = Array(list.prefix(limit))
        let next: Any = list.count > limit ? String(page.last?.summary.id ?? 0) : NSNull()
        return json(["items": page.map(Self.serverFields), "nextCursor": next])
    }

    /// PATCH /admin/inquiries/{id} — `{status, assignee?, answer?}`
    /// 서버(develop)는 status 만 저장하고 반려가 없어요. 목 서버는 백엔드 협의안(담당자 · 반려 사유 저장)대로 흉내 내요.
    func patch(id: Int, request: ServerInquiryPatchRequestDTO, now: Date = Date()) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = inboxIndex(id: id) else { return nil }
        let status = InquiryStatus(serverValue: request.status)
        if let assignee = request.assignee { records[index].assignee = assignee }
        let actor = records[index].assignee ?? "담당자"
        if status != records[index].summary.status {
            records[index].summary.status = status
            records[index].history.append(InquiryHistoryDTO(status: status, occurredAt: now, note: "", actor: actor))
        }
        if status == .rejected, let reason = request.answer {
            records[index].summary.reply = InquiryReplyDTO(department: Self.managerDepartment, body: reason, repliedAt: now)
        }
        return json(["id": String(id), "status": status.serverValue])
    }

    /// POST /admin/inquiries/{id}/answer — 답변 완료로 바꾸고 작성자 문의에도 보여요.
    func answer(id: Int, request: ServerInquiryAnswerRequestDTO, now: Date = Date()) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = inboxIndex(id: id) else { return nil }
        let actor = records[index].assignee ?? "담당자"
        records[index].summary.status = .answered
        records[index].summary.reply = InquiryReplyDTO(department: Self.managerDepartment, body: request.text, repliedAt: now)
        records[index].history.append(InquiryHistoryDTO(status: .answered, occurredAt: now, note: "", actor: actor))
        if let ruleId = request.referenceRuleId.flatMap(Int.init), let rule = Self.ruleTitles[ruleId] {
            records[index].reference = InquiryReferenceDTO(kind: .rule, id: ruleId, title: rule.title, summary: rule.summary)
        }
        return json(["id": String(id), "status": "답변 완료", "answer": ["who": actor, "at": MockBoardStore.pythonISO(now), "text": request.text]])
    }

    private func inboxIndex(id: Int) -> Int? {
        records.firstIndex { $0.summary.id == id && $0.summary.department == Self.managerDepartment }
    }

    static func departmentName(_ department: InquiryDepartment) -> String {
        switch department {
        case .leader: return "Leader"
        case .nativeOps: return "NativeOps"
        case .pmo: return "PMO"
        case .fa: return "FA"
        case .unknown: return "담당 부서"
        }
    }
}
