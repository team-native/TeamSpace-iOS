import Foundation

/// POST /approvals 요청 — 작성(임시 저장) · 제출을 한 번에 (TeamSpace-backend develop `workflows.ApprovalCreate`)
/// 작성 화면 항목은 순서를 지키려고 `details.fields` 에 그대로 담고, 서버가 쓰는 항목(type · project · useDate · period · staff)은 따로 채워요.
struct ServerApprovalCreateRequestDTO: Encodable, Equatable {
    struct Details: Encodable, Equatable {
        struct Field: Encodable, Equatable {
            let title: String
            let value: String
        }
        let fields: [Field]
    }

    let kind: String
    let type: String
    let title: String
    let amount: Int
    /// 작성 중 · 결재 대기
    let status: String
    let project: String
    let useDate: String
    let period: String
    let reason: String
    let staff: [String: Int]
    let files: [String]
    let details: Details

    init(_ draft: DocumentDraft, submit: Bool) {
        func field(_ titles: String...) -> String {
            let value = draft.fields.first { titles.contains($0.title) }?.value ?? ""
            return value == "-" ? "" : value
        }
        kind = draft.kind.serverValue
        switch draft.kind {
        case .expense: type = field("비용 유형")
        case .staffing: type = ""
        default: type = field("요청 종류", "요청 분류")
        }
        title = draft.title
        amount = draft.amount ?? 0
        status = submit ? "결재 대기" : "작성 중"
        project = field("프로젝트")
        useDate = field("사용 예정일", "희망 반영일", "희망 처리일")
        period = field("투입 기간", "기간")
        reason = draft.reason
        let role = field("필요 직군")
        let count = Int(field("인원").filter(\.isNumber)) ?? 0
        staff = draft.kind == .staffing && !role.isEmpty && count > 0 ? [role: count] : [:]
        // 서버는 업로드한 파일 ID 만 받아요. 앱 첨부는 아직 이름뿐이라 보내지 않아요.
        files = []
        details = Details(fields: draft.fields.map { Details.Field(title: $0.title, value: $0.value) })
    }
}

/// POST /approvals 응답 — `{id, status}`
struct ServerApprovalCreatedDTO: Decodable {
    let id: Int
    let status: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
    }

    private enum CodingKeys: String, CodingKey { case id, status }
}

extension ApprovalKind {
    /// 서버 결재 종류 이름
    var serverValue: String {
        switch self {
        case .expense: return "비용 승인"
        case .staffing: return "인력 지원"
        case .projectRequest: return "프로젝트 요청"
        case .operationRequest: return "운영 요청"
        case .other, .unknown: return "기타 내부 문서"
        }
    }
}
