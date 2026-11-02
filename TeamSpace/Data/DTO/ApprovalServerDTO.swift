import Foundation

/// GET /approvals · /approvals/{id} 의 한 건 — `{id, ...결재 payload, author, authorId, date, line, files, comments, received}`
/// (TeamSpace-backend develop `workflows._approval_item`)
struct ServerApprovalDTO: Decodable {
    struct Step: Decodable {
        let who: String
        let userId: Int?
        /// 기안 · 검토 · 승인
        let role: String
        /// done · now · wait
        let state: String
        /// 처리 시각(isoformat) 또는 "대기" · "검토 중"
        let at: String

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            who = (try? container.decodeIfPresent(String.self, forKey: .who)) ?? ""
            userId = try? container.decodeIntOrString(forKey: .userId)
            role = (try? container.decodeIfPresent(String.self, forKey: .role)) ?? ""
            state = (try? container.decodeIfPresent(String.self, forKey: .state)) ?? "wait"
            at = (try? container.decodeIfPresent(String.self, forKey: .at)) ?? ""
        }

        private enum CodingKeys: String, CodingKey { case who, userId, role, state, at }
    }

    /// `details` — 앱이 작성 화면 항목을 순서대로 담아 보내요. `{fields: [{title, value}]}`
    struct Details: Decodable {
        struct Field: Decodable {
            let title: String
            let value: String
        }
        let fields: [Field]?
    }

    struct File: Decodable {
        let filename: String
        let size: Int
    }

    struct Comment: Decodable {
        let who: String
        let text: String
        let createdAt: Date?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            who = (try? container.decodeIfPresent(String.self, forKey: .who)) ?? ""
            text = (try? container.decodeIfPresent(String.self, forKey: .text)) ?? ""
            createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt)).flatMap { $0.flatMap(ServerDate.parse) }
        }

        private enum CodingKeys: String, CodingKey { case who, text, createdAt }
    }

    let id: Int
    let kind: String
    let type: String
    let title: String
    let amountValue: Int?
    let status: String
    let project: String
    let useDate: String
    let period: String
    let reason: String
    let rejectReason: String
    let author: String
    let authorId: Int?
    let date: Date?
    let line: [Step]
    let files: [File]
    let comments: [Comment]
    let detailFields: [ApprovalField]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func text(_ key: CodingKeys) -> String { (try? container.decodeIfPresent(String.self, forKey: key)) ?? "" }
        id = try container.decodeIntOrString(forKey: .id)
        kind = text(.kind)
        type = text(.type)
        title = text(.title)
        amountValue = try? container.decodeIfPresent(Int.self, forKey: .amountValue)
        status = text(.status)
        project = text(.project)
        useDate = text(.useDate)
        period = text(.period)
        reason = text(.reason)
        rejectReason = text(.rejectReason)
        author = text(.author)
        authorId = try? container.decodeIntOrString(forKey: .authorId)
        date = ServerDate.parse(text(.updatedAt)) ?? ServerDate.parse(text(.date))
        line = (try? container.decodeIfPresent([Step].self, forKey: .line)) ?? []
        files = (try? container.decodeIfPresent([File].self, forKey: .files)) ?? []
        comments = (try? container.decodeIfPresent([Comment].self, forKey: .comments)) ?? []
        detailFields = ((try? container.decodeIfPresent(Details.self, forKey: .details))??.fields ?? [])
            .map { ApprovalField(title: $0.title, value: $0.value) }
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, type, title, amountValue, status, project, useDate, period, reason, rejectReason, author, authorId, date, updatedAt
        case line, files, comments, details
    }

    var approvalKind: ApprovalKind {
        switch kind {
        case "비용 승인": return .expense
        case "인력 지원": return .staffing
        case "프로젝트 요청": return .projectRequest
        case "운영 요청": return .operationRequest
        case "기타 내부 문서": return .other
        default: return .unknown
        }
    }

    func toItem() -> ApprovalItem {
        let kind = approvalKind
        let staffing = [type, period].filter { !$0.isEmpty }.joined(separator: " · ")
        return ApprovalItem(
            id: id,
            kind: kind,
            title: title,
            amount: kind == .staffing ? nil : amountValue,
            status: ApprovalStatus(serverValue: status),
            requesterName: author,
            requesterDepartment: "",
            summary: kind == .staffing && !staffing.isEmpty ? staffing : nil,
            updatedAt: date ?? Date(timeIntervalSince1970: 0)
        )
    }

    /// 결재선은 기안 단계를 빼고 보여줘요. 단계 ID 는 `line` 의 순서예요.
    func toDetail(viewerId: Int?) -> ApprovalDetail {
        let item = toItem()
        let steps = line.enumerated().filter { $0.element.role != "기안" }
        let lastDone = steps.last { $0.element.state == "done" }?.offset
        let approvers = steps.map { index, step in
            let status: ApproverStatus
            switch step.state {
            case "done": status = item.status == .rejected && index == lastDone ? .rejected : .approved
            case "now": status = item.status.isWaiting ? .reviewing : .waiting
            default: status = .waiting
            }
            return Approver(id: index, name: step.who, role: step.role, status: status, note: Self.note(for: step, status: status))
        }
        let myStep = steps.first { $0.element.userId == viewerId && $0.element.state == "now" }?.offset
        return ApprovalDetail(
            item: item,
            fields: fields(for: item.kind),
            reason: reason,
            approvers: approvers,
            attachments: files.map { ApprovalAttachment(name: $0.filename, sizeText: Self.sizeText($0.size)) },
            comments: comments.enumerated().map { index, comment in
                ApprovalComment(id: index + 1, authorName: comment.who, body: comment.text, createdAt: comment.createdAt ?? item.updatedAt)
            },
            isMine: viewerId != nil && authorId == viewerId,
            myApprovalId: item.status.isWaiting ? myStep : nil
        )
    }

    /// 07-4 · 07-5 내 문서 한 건. 결재선(line)에서 현재 결재자 · 최종 결재자를 찾아요.
    /// 결재 요청 전에 취소한 것(=임시 저장 삭제)은 nil
    func toMyDocument() -> MyDocument? {
        let item = toItem()
        let steps = line.filter { $0.role != "기안" }
        if item.status == .cancelled, steps.isEmpty { return nil }
        let current = steps.firstIndex { $0.state == "now" }
        let decided = item.status == .approved || item.status == .rejected ? steps.last { $0.state == "done" } : nil
        let submitted = item.status == .draft ? nil : line.first { $0.role == "기안" }.flatMap { ServerDate.parse($0.at) } ?? item.updatedAt
        return MyDocument(
            id: item.id,
            kind: item.kind,
            title: item.title,
            amount: item.amount,
            status: item.status,
            projectName: project.isEmpty ? nil : project,
            summary: item.status == .draft && !reason.isEmpty ? reason : nil,
            submittedAt: submitted,
            updatedAt: item.updatedAt,
            currentApprover: item.status.isWaiting ? current.map { DocumentPerson(name: steps[$0].who, department: "") } : nil,
            currentStepTitle: item.status.isWaiting ? current.map { "\($0 + 1)차 \(steps[$0].role) 중" } : nil,
            decidedBy: decided.map { DocumentPerson(name: $0.who, department: "") },
            decidedAt: decided.flatMap { ServerDate.parse($0.at) },
            rejectReason: item.status == .rejected && !rejectReason.isEmpty ? rejectReason : nil
        )
    }

    /// 상세 항목 — 앱이 보낸 `details.fields` 가 있으면 그대로, 없으면 payload 에 값이 있는 것만
    private func fields(for kind: ApprovalKind) -> [ApprovalField] {
        guard detailFields.isEmpty else { return detailFields }
        let pairs: [(String, String)]
        switch kind {
        case .expense:
            pairs = [("비용 유형", type), ("프로젝트", project), ("사용 예정일", useDate)]
        case .staffing:
            pairs = [("프로젝트", project), ("필요 인원", type), ("투입 기간", period)]
        default:
            pairs = [("프로젝트", project), ("사용 예정일", useDate)]
        }
        return pairs.filter { !$0.1.isEmpty }
            .map { ApprovalField(title: $0.0, value: $0.1) }
    }

    private static func note(for step: Step, status: ApproverStatus) -> String {
        switch status {
        case .approved, .rejected:
            guard let date = ServerDate.parse(step.at) else { return "처리 완료" }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "MM.dd HH:mm"
            return "\(formatter.string(from: date)) \(status == .rejected ? "반려" : "승인")"
        case .reviewing: return "지금 검토 중"
        case .waiting, .unknown: return "이전 단계 승인 후"
        }
    }

    private static func sizeText(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// POST /approvals/{id}/approve · reject 응답 — `{id, status}`
struct ServerApprovalDecisionDTO: Decodable {
    let status: String
}

/// POST /approvals/{id}/reject 요청
struct ServerApprovalRejectRequestDTO: Codable, Equatable {
    let reason: String
}

/// POST /approvals/{id}/comments 요청 · 응답
struct ServerApprovalCommentRequestDTO: Codable, Equatable {
    let text: String
}

/// GET /me 에서 내 id 만 — 결재선에서 내 차례 · 내가 올린 결재를 찾을 때 써요.
struct ServerMeIdDTO: Decodable {
    let id: Int

    init(from decoder: Decoder) throws {
        id = try decoder.container(keyedBy: CodingKeys.self).decodeIntOrString(forKey: .id)
    }

    private enum CodingKeys: String, CodingKey { case id }
}

extension ApprovalStatus {
    /// 작성 중 · 결재 대기 · 검토 중 · 승인 · 반려 · 취소
    init(serverValue: String) {
        switch serverValue {
        case "작성 중": self = .draft
        case "결재 대기": self = .pending
        case "검토 중": self = .reviewing
        case "승인": self = .approved
        case "반려": self = .rejected
        case "취소": self = .cancelled
        default: self = ApprovalStatus(rawValue: serverValue) ?? .unknown
        }
    }
}
