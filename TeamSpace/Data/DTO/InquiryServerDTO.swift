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
    /// 실명 문의의 작성자 (익명이면 "익명")
    let author: String?
    /// 담당자 — 서버가 저장하면 읽어요. (백엔드 협의 중)
    let assignee: String?
    /// 답변과 함께 보여줄 규칙 — 서버가 저장하면 읽어요. (백엔드 협의 중)
    let reference: InquiryReferenceDTO?
    /// 추가 메시지 `[{text, at, who}]`
    let replies: [Reply]

    struct Reply: Decodable {
        let text: String
        let at: Date?
        let who: String?

        private enum CodingKeys: String, CodingKey { case text, at, who }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            text = (try? container.decodeIfPresent(String.self, forKey: .text)) ?? ""
            at = (try? container.decodeIfPresent(String.self, forKey: .at)).flatMap { $0.flatMap(ServerDate.parse) }
            who = try? container.decodeIfPresent(String.self, forKey: .who)
        }
    }

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
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        assignee = try? container.decodeIfPresent(String.self, forKey: .assignee)
        reference = try? container.decodeIfPresent(InquiryReferenceDTO.self, forKey: .reference)
        replies = (try? container.decodeIfPresent([Reply].self, forKey: .replies)) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, dept, title, body, anonymous, status, steps, answer, createdAt, author, assignee, reference, replies
    }

    var departmentValue: InquiryDepartment { department }

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
                actor: status == finalStatus ? answer?.who : status == .reviewing ? assignee : nil
            ))
        }
        if history.isEmpty {
            history = [InquiryHistory(status: .received, occurredAt: receivedAt, note: Self.note(for: .received, department: summary.department))]
        }
        return InquiryDetail(
            inquiry: summary,
            history: history,
            reference: reference?.toEntity(),
            followUps: replies.filter { !$0.text.isEmpty }.map {
                InquiryFollowUp(text: $0.text, author: $0.who ?? "익명", sentAt: $0.at ?? receivedAt)
            }
        )
    }

    /// 11-5 · 11-6 담당자 화면 — 익명 문의는 작성자를 보여주지 않아요.
    func toInboxItem() -> InquiryInboxItem {
        let detail = toDetail()
        return InquiryInboxItem(
            inquiry: detail.inquiry,
            authorName: anonymous ? nil : author,
            assignee: assignee,
            history: detail.history,
            reference: detail.reference
        )
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

/// PATCH /admin/inquiries/{id} 요청 — 서버는 status 만 읽어요. assignee · answer 는 백엔드 협의 중이에요.
struct ServerInquiryPatchRequestDTO: Codable, Equatable {
    let status: String
    var assignee: String?
    /// 반려 사유
    var answer: String?
}

/// POST /admin/inquiries/{id}/answer 요청 — 서버 값은 모두 문자열이에요. (referenceRuleId 는 백엔드 협의 중)
struct ServerInquiryAnswerRequestDTO: Codable, Equatable {
    let text: String
    var referenceRuleId: String?
}

/// POST /inquiries/{id}/comments 요청 · 응답 `{text, at, who}`
struct ServerInquiryCommentRequestDTO: Codable, Equatable {
    let text: String
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
