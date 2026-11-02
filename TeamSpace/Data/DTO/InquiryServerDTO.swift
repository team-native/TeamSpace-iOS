import Foundation

/// GET /inquiries 의 한 항목 (TeamSpace-backend develop `community.create_inquiry` 가 저장한 payload)
/// steps 는 [접수, 검토, 답변] 시각이고 아직 안 된 단계는 빈 문자열이에요.
struct ServerInquiryDTO: Decodable {
    struct Answer: Decodable {
        let who: String?
        let at: Date?
        let text: String
    }

    let id: Int
    let type: String?
    let dept: String
    let title: String
    let body: String
    let anonymous: Bool
    let status: String
    /// [접수, 검토, 답변] — 빈 문자열은 nil
    let steps: [Date?]
    let answer: Answer?
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        type = try? container.decodeIfPresent(String.self, forKey: .type)
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        body = (try? container.decodeIfPresent(String.self, forKey: .body)) ?? ""
        anonymous = (try? container.decodeIfPresent(Bool.self, forKey: .anonymous)) ?? false
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "접수"
        let rawSteps = (try? container.decodeIfPresent([String].self, forKey: .steps)) ?? []
        steps = rawSteps.map { $0.isEmpty ? nil : ServerDate.parse($0) }
        answer = try? container.decodeIfPresent(Answer.self, forKey: .answer)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, dept, title, body, anonymous, status, steps, answer, createdAt
    }

    private var department: InquiryDepartment { InquiryDepartment(serverValue: dept) }
    private var inquiryStatus: InquiryStatus { InquiryStatus(serverValue: status) }
    private var receivedAt: Date { steps.first.flatMap { $0 } ?? createdAt ?? Date() }

    func toEntity() -> InquirySummary {
        InquirySummary(
            id: id,
            department: department,
            title: title,
            body: body,
            isAnonymous: anonymous,
            createdAt: receivedAt,
            status: inquiryStatus,
            reply: answer.map {
                InquiryReply(department: department, body: $0.text, repliedAt: $0.at ?? steps.last.flatMap { $0 } ?? receivedAt)
            }
        )
    }

    /// 서버는 단계별 메모 · 함께 볼 규칙을 주지 않아 단계 이름으로 메모를 채워요.
    func toDetail() -> InquiryDetail {
        let summary = toEntity()
        let finalStatus: InquiryStatus = inquiryStatus == .rejected ? .rejected : .answered
        let stepStatuses: [InquiryStatus] = [.received, .reviewing, finalStatus]
        var history: [InquiryHistory] = []
        for (index, date) in steps.prefix(3).enumerated() {
            guard let date else { continue }
            let status = stepStatuses[index]
            history.append(InquiryHistory(
                status: status,
                occurredAt: date,
                note: Self.note(for: status, department: summary.department),
                actor: status == finalStatus ? answer?.who : nil
            ))
        }
        if history.isEmpty {
            history = [InquiryHistory(status: .received, occurredAt: receivedAt, note: Self.note(for: .received, department: summary.department))]
        }
        return InquiryDetail(inquiry: summary, history: history, reference: nil)
    }

    static func note(for status: InquiryStatus, department: InquiryDepartment) -> String {
        switch status {
        case .received: return "\(department.serverValue)에 전달"
        case .reviewing: return "검토 시작"
        case .answered: return "공식 답변 등록"
        case .rejected: return "반려 사유 등록"
        case .unknown: return ""
        }
    }
}

/// POST /inquiries 요청
struct ServerInquiryCreateRequestDTO: Codable, Equatable {
    /// 서버 값: 문의 · 건의 · 불편 신고 — 앱 작성 화면은 종류를 고르지 않아 "문의"
    static let defaultType = "문의"

    let type: String
    let dept: String
    let title: String
    let body: String
    let anonymous: Bool
}

/// POST /inquiries 응답 `{id, status}`
struct ServerInquiryCreatedDTO: Decodable {
    let id: Int
    let status: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        status = try? container.decodeIfPresent(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case id, status
    }
}

extension InquiryStatus {
    /// 서버 상태 (접수 · 검토 중 · 답변 완료 · 해결됨). 해결됨은 답변 완료로 봐요.
    init(serverValue: String) {
        switch serverValue.trimmingCharacters(in: .whitespaces) {
        case "접수": self = .received
        case "검토 중", "검토중": self = .reviewing
        case "답변 완료", "해결됨": self = .answered
        case "반려": self = .rejected
        default: self = InquiryStatus(rawValue: serverValue) ?? .unknown
        }
    }

    /// 목 서버에서 쓰는 서버 상태 이름
    var serverValue: String {
        switch self {
        case .received, .unknown: return "접수"
        case .reviewing: return "검토 중"
        case .answered: return "답변 완료"
        case .rejected: return "반려"
        }
    }
}

extension InquiryDepartment {
    /// 서버 `dept` (자유 문자열) — 화면 이름과 같아요.
    var serverValue: String {
        switch self {
        case .leader: return "Leader"
        case .nativeOps: return "NativeOps"
        case .pmo: return "PMO"
        case .fa: return "FA"
        case .unknown: return ""
        }
    }

    init(serverValue: String) {
        let value = serverValue.trimmingCharacters(in: .whitespaces)
        self = Self.selectable.first {
            $0.serverValue.caseInsensitiveCompare(value) == .orderedSame || $0.rawValue == value
        } ?? .unknown
    }
}
