import Foundation

/// 08-3 ~ 08-7 모집 · 참여 응답의 `data`
/// 명세서에는 `POST /projects/{id}/apply` 만 있어 나머지는 Figma 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct RecruitmentDTO: Codable {
    let projectId: Int
    let projectName: String
    let opening: ProjectOpeningDTO
    let headline: String
    let introduction: String
    let activityPeriod: String
    let activityHours: String
    let recruitStart: Date
    let recruitEnd: Date
    let department: String
    let duties: [String]
    let requirements: String
    let applyTip: String
    let pmName: String
    let documentTitle: String?
    let isJoined: Bool
    let myApplicationStatus: ApplicationStatus?

    func toEntity() -> RecruitmentPost {
        RecruitmentPost(
            projectId: projectId, projectName: projectName, opening: opening.toEntity(), headline: headline,
            introduction: introduction, activityPeriod: activityPeriod, activityHours: activityHours,
            recruitStart: recruitStart, recruitEnd: recruitEnd, department: department, duties: duties,
            requirements: requirements, applyTip: applyTip, pmName: pmName, documentTitle: documentTitle,
            isJoined: isJoined, myApplicationStatus: myApplicationStatus
        )
    }
}

/// POST /projects/{id}/apply 요청 바디
struct ApplyRequestDTO: Codable {
    let openingId: Int
    let availability: String
    let message: String

    init(_ draft: ApplicationDraft) {
        openingId = draft.openingId
        availability = draft.availability.rawValue
        message = draft.message
    }
}

struct ApplicationDTO: Codable {
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
    let reviewedAt: Date?
    let resultDueDate: Date?
    var decidedAt: Date?
    var resultReason: String?

    func toEntity() -> ProjectApplication {
        ProjectApplication(
            id: id, projectId: projectId, projectName: projectName, role: role, department: department,
            status: status, appliedAt: appliedAt, headcount: headcount, pmName: pmName, message: message,
            portfolioUrl: portfolioUrl, reviewedAt: reviewedAt, resultDueDate: resultDueDate,
            decidedAt: decidedAt, resultReason: resultReason
        )
    }
}

struct ApplicationListResponseDTO: Codable {
    let list: [ApplicationDTO]
}

struct ApplicantDTO: Codable {
    let id: Int
    let name: String
    let role: String
    var status: ApplicationStatus
    let appliedAt: Date
    let availability: Availability
    let message: String
    let portfolioUrl: String?
    var resultReason: String?

    func toEntity() -> Applicant {
        Applicant(
            id: id, name: name, role: role, status: status, appliedAt: appliedAt, availability: availability,
            message: message, portfolioUrl: portfolioUrl, resultReason: resultReason
        )
    }
}

struct ApplicantBoardDTO: Codable {
    let projectName: String
    let pmName: String
    let opening: ProjectOpeningDTO
    let recruitStart: Date
    let recruitEnd: Date
    let resultDueDate: Date
    let applicants: [ApplicantDTO]

    func toEntity() -> ApplicantBoard {
        ApplicantBoard(
            projectName: projectName, pmName: pmName, opening: opening.toEntity(), recruitStart: recruitStart,
            recruitEnd: recruitEnd, resultDueDate: resultDueDate, applicants: applicants.map { $0.toEntity() }
        )
    }
}

/// POST /projects/{id}/applicants/{applicantId}/decision 요청 바디
struct ApplicantDecisionRequestDTO: Codable {
    let decision: String
    let reason: String
}
