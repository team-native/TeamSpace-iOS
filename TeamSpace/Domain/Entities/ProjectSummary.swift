import Foundation

/// 모집 중인 자리 (예: iOS 개발 1명 · 11월 ~ 12월)
struct ProjectOpening: Equatable, Identifiable, Sendable {
    let id: Int
    /// 직군 (예: "iOS", "에디터") — 목록의 "iOS 1명 모집"
    let role: String
    /// 자리 이름 (예: "iOS 개발")
    let title: String
    let headcount: Int
    let startDate: Date
    let endDate: Date
    let description: String
}

/// 08-1 프로젝트 목록 한 건
struct ProjectSummary: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let summary: String
    /// 담당 부서 (예: NativeLab)
    let department: String
    let pmName: String
    let memberCount: Int
    let status: ProjectRunStatus
    let startDate: Date
    let endDate: Date
    /// 0~100
    let progress: Int
    let openings: [ProjectOpening]
    /// 완료된 프로젝트의 결과 안내 (예: "회고 문서 공개")
    let resultNote: String?
    let updatedAt: Date

    var isRecruiting: Bool { !openings.isEmpty }
}

/// 함께하는 사람
struct ProjectMember: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    /// 예) PM · Design · iOS
    let role: String
}

/// 관련 문서 · 일정
struct ProjectRelatedItem: Equatable, Identifiable, Sendable {
    enum Kind: String, UnknownCaseDecodable, Sendable {
        case document = "DOCUMENT"
        case schedule = "SCHEDULE"
        case unknown = "UNKNOWN"

        static let unknownCase: Kind = .unknown
    }

    let id: Int
    let kind: Kind
    let title: String
    let date: Date?
}

/// 08-2 프로젝트 상세
struct ProjectDetail: Equatable, Sendable {
    let project: ProjectSummary
    let members: [ProjectMember]
    let relatedItems: [ProjectRelatedItem]
    /// 내가 참여 중인 프로젝트인지
    let isJoined: Bool
}
