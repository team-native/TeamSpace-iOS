import Foundation

/// 03 팀원 — 목록에 보이는 요약
struct Member: Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String
    let department: Department
    let roles: [UserRole]
    /// 이름 옆 칩 (예: Leader · OL · Design)
    let tag: String
    /// 이름 아래 한 줄 (예: Product Designer)
    let position: String
    let joinedAt: Date
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

/// GET /users/{userId}
struct MemberDetail: Equatable, Sendable {
    let member: Member
    let email: String
    /// 예) 프로젝트 일정 · 인력 관리
    let responsibility: String
    /// 기수
    let generation: Int
    let statusMessage: String?
    let projects: [MemberProject]
    let interests: [String]
}

/// GET /organization/tree — 부서 하나
struct OrganizationUnit: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let summary: String
    let department: Department
    let members: [Member]
}

/// GET /organization/tree
struct OrganizationTree: Equatable, Sendable {
    let leader: Member
    let units: [OrganizationUnit]
}
