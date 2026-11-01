import Foundation

final class NoticeRepositoryImpl: NoticeRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchNotices() async throws -> [NoticeSummary] {
        try await request(Endpoint(method: .get, path: "notices"), as: NoticeListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchNotice(id: Int) async throws -> NoticeDetail {
        try await request(Endpoint(method: .get, path: "notices/\(id)"), as: NoticeDetailDTO.self).toEntity()
    }

    func acknowledge(noticeId: Int) async throws -> Date {
        try await request(Endpoint(method: .post, path: "notices/\(noticeId)/acknowledge"), as: NoticeAcknowledgeResponseDTO.self)
            .acknowledgedAt
    }

    func publish(_ draft: NoticeDraft, asDraft: Bool) async throws -> NoticeSummary {
        let body = NoticePublishRequestDTO(
            audience: draft.audience,
            isImportant: draft.isImportant,
            isPinned: draft.isPinned,
            title: draft.title,
            body: draft.body,
            attachments: draft.attachments.map { .init(fileName: $0.fileName, data: $0.data.base64EncodedString()) },
            scheduledAt: draft.timing == .scheduled ? draft.scheduledAt : nil,
            sendsPush: draft.sendsPush,
            isDraft: asDraft
        )
        return try await request(Endpoint(method: .post, path: "notices", body: body), as: NoticeSummaryDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
