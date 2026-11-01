import Foundation

/// 11 문의 가짜 저장소 — Figma 11-1 수정본 · 11-4 · 11-7 예시 (날짜는 오늘 기준)
/// 42 번은 02 알림의 "내 문의에 답변이 도착했어요"와 같은 문의예요.
final class MockInquiryStore: @unchecked Sendable {
    private struct Record {
        var summary: InquirySummaryDTO
        var history: [InquiryHistoryDTO]
        let reference: InquiryReferenceDTO?
    }

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
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(12, 10.33), note: "예약 현황과 운영 기준 확인"),
                    InquiryHistoryDTO(status: .answered, occurredAt: at(10, 14), note: "공식 답변 등록")
                ],
                reference: InquiryReferenceDTO(kind: .rule, id: 5, title: "회의와 의사결정 원칙", summary: "우선순위, 진행 방법 등")
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
                    InquiryHistoryDTO(status: .reviewing, occurredAt: at(13, 10.33), note: "학교 시설 이용 규정 확인"),
                    InquiryHistoryDTO(status: .rejected, occurredAt: at(11, 14), note: "반려 사유 등록")
                ],
                reference: InquiryReferenceDTO(kind: .notice, id: nil, title: "회의실 이용 안내", summary: "예약 현황 · 이용 시간 · 문의처")
            )
        ]
    }

    /// GET /inquiries/mine
    func mineJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(InquiryListResponseDTO(list: records.map(\.summary)))
    }

    /// GET /inquiries/{id}
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let record = records.first(where: { $0.summary.id == id }) else { return nil }
        return envelope(InquiryDetailDTO(inquiry: record.summary, history: record.history, reference: record.reference))
    }

    /// POST /inquiries — 접수 상태로 추가해요.
    func submit(_ request: InquirySubmitRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        let id = (records.map(\.summary.id).max() ?? 0) + 1
        let now = Date()
        let summary = InquirySummaryDTO(
            id: id, department: request.department, title: request.title, body: request.body,
            isAnonymous: request.isAnonymous, createdAt: now, status: .received, reply: nil
        )
        let note = "\(Self.departmentName(request.department))에 전달"
        records.append(Record(summary: summary, history: [InquiryHistoryDTO(status: .received, occurredAt: now, note: note)], reference: nil))
        return envelope(summary)
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

    private func envelope<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
