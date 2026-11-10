import Foundation

/// 03 팀원 — 목록에 보이는 요약
struct Member: Equatable, Hashable, Identifiable, Sendable {
    /// 조직도 사람은 "member-02", 조직도에 없는 계정은 숫자 문자열 "37" 이에요.
    let id: String
    let name: String
    let department: Department
    let roles: [UserRole]
    /// 이름 옆 칩 (예: Leader · OL · Design)
    let tag: String
    /// 이름 아래 한 줄 (예: Product Designer)
    let position: String
    let joinedAt: Date
    /// 조직도에는 있지만 아직 계정이 연결되지 않은 사람 — 가입 승인 때 고를 수 있어요.
    var needsAccount = false
}

/// 팀원 상세 · 참여 중인 프로젝트
struct MemberProject: Equatable, Identifiable, Sendable {
    enum Status: String, UnknownCaseDecodable, Sendable {
        case inProgress = "IN_PROGRESS"
        case completed = "COMPLETED"
        case unknown = "UNKNOWN"

        static let unknownCase: Status = .unknown
    }

    let id: Int
    let name: String
    /// 예) 독서 기록 앱
    let summary: String
    /// 예) PM
    let role: String
    let status: Status
}

/// GET /people/{id}
struct MemberDetail: Equatable, Sendable {
    let member: Member
    let email: String
    /// 예) 프로젝트 일정 · 인력 관리
    let responsibility: String
    /// 기수 — 서버 `cohort` 가 비어 있으면 nil
    let generation: Int?
    let statusMessage: String?
    let projects: [MemberProject]
    let interests: [String]
}

/// 조직도 — 부서 하나
struct OrganizationUnit: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let summary: String
    let department: Department
    let members: [Member]
}

/// 조직도
struct OrganizationTree: Equatable, Sendable {
    let leader: Member
    let units: [OrganizationUnit]
}
