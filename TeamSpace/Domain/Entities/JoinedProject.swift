import Foundation

/// 프로젝트 진행 상태
enum ProjectRunStatus: String, UnknownCaseDecodable, Hashable, Sendable {
    case planned = "PLANNED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case unknown = "UNKNOWN"

    static let unknownCase: ProjectRunStatus = .unknown
}

/// 07-6 내가 참여 중인 프로젝트
struct JoinedProject: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    /// 예) 독서 기록 앱
    let summary: String
    let startDate: Date
    let endDate: Date
    let status: ProjectRunStatus
}
