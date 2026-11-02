import Foundation

final class NoticeRepositoryImpl: NoticeRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchNotices(cursor: String?, limit: Int) async throws -> CursorPage<NoticeSummary> {
        var query = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
        let page = try await request(
            Endpoint(method: .get, path: "notices", queryItems: query),
            as: CursorPageDTO<ServerNoticeItemDTO>.self
        )
        return CursorPage(items: page.items.map { $0.toEntity() }, nextCursor: page.nextCursor)
    }

    func fetchNotice(id: Int) async throws -> NoticeDetail {
        try await request(Endpoint(method: .get, path: "notices/\(id)"), as: ServerNoticeItemDTO.self).toDetail()
    }

    func acknowledge(noticeId: Int) async throws {
        _ = try await request(Endpoint(method: .post, path: "notices/\(noticeId)/confirm"), as: IgnoredJSONValue.self)
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
