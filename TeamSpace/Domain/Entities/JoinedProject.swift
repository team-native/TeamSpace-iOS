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
    /// 예) "2026.08 – 2026.11" · "11.20 납품" — 서버는 기간을 글로만 줘요.
    let period: String?
    let status: ProjectRunStatus
}
