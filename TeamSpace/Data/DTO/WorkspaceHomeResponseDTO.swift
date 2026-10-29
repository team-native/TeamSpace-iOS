import Foundation

/// GET /workspace/home 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-1 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct WorkspaceHomeResponseDTO: Decodable {
    let affiliation: String
    let todo: TodoSummaryDTO
    let notification: NotificationPreviewDTO?
    let receivedApproval: ApprovalPreviewDTO?
    let submittedDocument: SubmittedDocumentDTO?
    let projects: [ProjectDTO]
    let schedules: [ScheduleDTO]
    let records: RecordsDTO

    struct TodoSummaryDTO: Decodable {
        let todayCount: Int
        let completedCount: Int
        let todayTitles: [String]
    }

    struct NotificationPreviewDTO: Decodable {
        let unreadCount: Int
        let title: String
        let subtitle: String
    }

    struct ApprovalPreviewDTO: Decodable {
        let documentId: Int
        let waitingCount: Int
        let title: String
        let requesterName: String
        let requestedAt: Date
    }

    struct SubmittedDocumentDTO: Decodable {
        let documentId: Int
        let title: String
        let amount: Int?
        let submittedAt: Date
        let status: ApprovalStatus
        let currentApproverName: String?
    }

    struct ProjectDTO: Decodable {
        let id: Int
        let name: String
        let pmName: String
        let team: String
        let memberCount: Int
        let progress: Int
    }

    struct ScheduleDTO: Decodable {
        let id: Int
        let scope: WorkspaceScheduleScope
        let title: String
        let startsAt: Date
        let endsAt: Date
        let place: String
        let note: String?
    }

    struct RecordsDTO: Decodable {
        let latestPost: PostDTO?
        let proposalCount: Int
        let latestProposal: ProposalDTO?
        let inquiries: [InquiryDTO]
    }

    struct PostDTO: Decodable {
        let title: String
        let createdAt: Date
    }

    struct ProposalDTO: Decodable {
        let title: String
        let status: ProposalStatus
        let recommendCount: Int
    }

    struct InquiryDTO: Decodable {
        let title: String
        let status: InquiryStatus
    }

    func toEntity() -> WorkspaceHome {
        WorkspaceHome(
            affiliation: affiliation,
            todo: WorkspaceTodoSummary(
                todayCount: todo.todayCount,
                completedCount: todo.completedCount,
                todayTitles: todo.todayTitles
            ),
            notification: notification.map {
                WorkspaceNotificationPreview(unreadCount: $0.unreadCount, title: $0.title, subtitle: $0.subtitle)
            },
            receivedApproval: receivedApproval.map {
                WorkspaceApprovalPreview(
                    documentId: $0.documentId,
                    waitingCount: $0.waitingCount,
                    title: $0.title,
                    requesterName: $0.requesterName,
                    requestedAt: $0.requestedAt
                )
            },
            submittedDocument: submittedDocument.map {
                WorkspaceSubmittedDocument(
                    documentId: $0.documentId,
                    title: $0.title,
                    amount: $0.amount,
                    submittedAt: $0.submittedAt,
                    status: $0.status,
                    currentApproverName: $0.currentApproverName
                )
            },
            projects: projects.map {
                WorkspaceProject(
                    id: $0.id, name: $0.name, pmName: $0.pmName, team: $0.team,
                    memberCount: $0.memberCount, progress: $0.progress
                )
            },
            schedules: schedules.map {
                WorkspaceSchedule(
                    id: $0.id, scope: $0.scope, title: $0.title, startsAt: $0.startsAt,
                    endsAt: $0.endsAt, place: $0.place, note: $0.note
                )
            },
            records: records.toEntity()
        )
    }
}

extension WorkspaceHomeResponseDTO.RecordsDTO {
    /// 07-1 · 10-1 "내가 남긴 기록"
    func toEntity() -> WorkspaceRecords {
        WorkspaceRecords(
            latestPost: latestPost.map { WorkspacePostPreview(title: $0.title, createdAt: $0.createdAt) },
            proposalCount: proposalCount,
            latestProposal: latestProposal.map {
                WorkspaceProposalPreview(title: $0.title, status: $0.status, recommendCount: $0.recommendCount)
            },
            inquiries: inquiries.map { WorkspaceInquiryPreview(title: $0.title, status: $0.status) }
        )
    }
}
