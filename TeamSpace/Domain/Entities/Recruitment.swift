import Foundation

/// 참여 신청 상태 (문서 결재 상태와 따로 관리)
enum ApplicationStatus: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case submitted = "SUBMITTED"   // 접수
    case reviewing = "IN_REVIEW"   // 검토 중
    case accepted = "ACCEPTED"     // 참여 확정
    case declined = "DECLINED"     // 미선정
    case canceled = "CANCELED"     // 신청 취소
    case unknown = "UNKNOWN"

    static let unknownCase: ApplicationStatus = .unknown

    /// 결과가 나기 전이라 취소할 수 있는 상태
    var isCancelable: Bool { self == .submitted || self == .reviewing }
}

/// 참여 가능한 시간
enum Availability: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case tenHours = "WEEKLY_10"
    case twentyHours = "WEEKLY_20"
    case fullTime = "FULL_TIME"
    case unknown = "UNKNOWN"

    static let unknownCase: Availability = .unknown
    static let selectable: [Availability] = [.tenHours, .twentyHours, .fullTime]
}

/// 08-3 모집 공고
struct RecruitmentPost: Equatable, Sendable {
    let projectId: Int
    let projectName: String
    let opening: ProjectOpening
    /// 큰 제목 (예: "Book-on의 다음 기능을\n함께 만들어요")
    let headline: String
    let introduction: String
    /// 예) "2026.11–12 · 출시 후 안정화 포함"
    let activityPeriod: String
    /// 예) "주 6시간 내외 · 협의 가능"
    let activityHours: String
    let recruitStart: Date
    let recruitEnd: Date
    let department: String
    let duties: [String]
    let requirements: String
    let applyTip: String
    let pmName: String
    let documentTitle: String?
    /// 이미 참여 중인 프로젝트
    let isJoined: Bool
    /// 이미 낸 신청 상태 (없으면 nil)
    let myApplicationStatus: ApplicationStatus?
}

/// 08-4 참여 신청서
struct ApplicationDraft: Equatable, Sendable {
    let openingId: Int
    let availability: Availability
    let message: String
}

/// 08-6 내 참여 신청 한 건
struct ProjectApplication: Equatable, Identifiable, Sendable {
    let id: Int
    let projectId: Int
    let projectName: String
    let role: String
    let department: String
    var status: ApplicationStatus
    let appliedAt: Date
    let headcount: Int
    let pmName: String
    let message: String
    let portfolioUrl: String?
    /// PM 이 확인한 시각
    let reviewedAt: Date?
    /// 결과 안내 예정일
    let resultDueDate: Date?
    let decidedAt: Date?
    let resultReason: String?
}

/// 08-7 지원자 한 명
struct Applicant: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let role: String
    var status: ApplicationStatus
    let appliedAt: Date
    let availability: Availability
    let message: String
    let portfolioUrl: String?
    var resultReason: String?
}

/// 08-7 지원자 검토 화면 전체
struct ApplicantBoard: Equatable, Sendable {
    let projectName: String
    let pmName: String
    let opening: ProjectOpening
    let recruitStart: Date
    let recruitEnd: Date
    let resultDueDate: Date
    var applicants: [Applicant]
}

/// 08-7 결과
enum ApplicantDecision: String, Sendable {
    case accept = "ACCEPT"
    case decline = "DECLINE"
}
