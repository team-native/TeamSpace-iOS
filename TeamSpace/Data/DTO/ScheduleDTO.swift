import Foundation

/// GET /workspace/schedules 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-7 ~ 07-9 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct ScheduleListResponseDTO: Decodable {
    let list: [ScheduleEventDTO]
}

struct ScheduleEventDTO: Codable {
    let id: Int
    let scope: WorkspaceScheduleScope
    let title: String
    let startsAt: Date
    let endsAt: Date
    let place: String
    let placeDetail: String?
    let organizerName: String
    let participantCount: Int
    let isChanged: Bool
    var myResponse: ScheduleResponse?
    var respondedAt: Date?

    func toEntity() -> ScheduleEvent {
        ScheduleEvent(
            id: id, scope: scope, title: title, startsAt: startsAt, endsAt: endsAt, place: place,
            placeDetail: placeDetail, organizerName: organizerName, participantCount: participantCount,
            isChanged: isChanged, myResponse: myResponse, respondedAt: respondedAt
        )
    }
}

/// GET /workspace/schedules/{id} 응답의 `data`
struct ScheduleDetailDTO: Codable {
    var event: ScheduleEventDTO
    let category: String
    let summary: String
    let host: String
    let audience: String
    let facilitator: String
    let agenda: [AgendaDTO]
    let agendaNote: String?
    let relatedDocument: RelatedDocumentDTO?
    let history: [ChangeDTO]
    let historyNote: String?
    var reminders: [ReminderTiming]

    struct AgendaDTO: Codable {
        let startsAt: Date
        let endsAt: Date
        let title: String
    }

    struct RelatedDocumentDTO: Codable {
        let title: String
        let owner: String
        let updatedAt: Date
    }

    struct ChangeDTO: Codable {
        let title: String
        let changedAt: Date
        let detail: String
    }

    func toEntity() -> ScheduleEventDetail {
        ScheduleEventDetail(
            event: event.toEntity(),
            category: category,
            summary: summary,
            host: host,
            audience: audience,
            facilitator: facilitator,
            agenda: agenda.map { ScheduleAgendaItem(startsAt: $0.startsAt, endsAt: $0.endsAt, title: $0.title) },
            agendaNote: agendaNote,
            relatedDocument: relatedDocument.map {
                ScheduleRelatedDocument(title: $0.title, owner: $0.owner, updatedAt: $0.updatedAt)
            },
            history: history.map { ScheduleChange(title: $0.title, changedAt: $0.changedAt, detail: $0.detail) },
            historyNote: historyNote,
            reminders: reminders
        )
    }
}

/// POST /workspace/schedules/{id}/response 요청 바디
struct ScheduleResponseRequestDTO: Codable {
    let response: String
}

/// PATCH /workspace/schedules/{id}/reminders 요청 · 응답 바디
struct ScheduleRemindersDTO: Codable {
    let reminders: [String]
}
