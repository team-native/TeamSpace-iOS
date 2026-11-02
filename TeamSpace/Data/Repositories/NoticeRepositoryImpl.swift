import Foundation
import UniformTypeIdentifiers

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

    /// 첨부를 하나씩 `POST /uploads` 로 올린 뒤, 받은 id 를 붙여 `POST /admin/notices` 로 게시해요.
    func publish(_ draft: NoticeDraft, asDraft: Bool) async throws -> NoticeSummary {
        var attachmentIds: [String] = []
        for attachment in draft.attachments {
            attachmentIds.append(try await upload(attachment))
        }
        let body = ServerNoticeCreateRequestDTO(draft: draft, attachmentIds: attachmentIds, asDraft: asDraft)
        let created = try await request(Endpoint(method: .post, path: "admin/notices", body: body), as: ServerIdResponseDTO.self)
        guard let id = Int(created.id) else { throw AppError.unknown("공지 번호를 읽지 못했어요.") }
        return NoticeSummary(
            id: id,
            category: NoticeCategory(serverKind: body.kind),
            title: draft.title,
            summary: ServerPostItemDTO.excerpt(of: draft.body),
            updatedAt: body.publishAt ?? Date(),
            isPinned: draft.isPinned,
            isImportant: draft.isImportant
        )
    }

    /// POST /uploads — 10MB 이하 파일
    private func upload(_ attachment: NoticeAttachment) async throws -> String {
        let file = MultipartFile(
            filename: attachment.fileName,
            mimeType: Self.mimeType(of: attachment.fileName),
            data: attachment.data
        )
        return try await request(Endpoint(method: .post, path: "uploads", file: file), as: ServerIdResponseDTO.self).id
    }

    static func mimeType(of fileName: String) -> String {
        UTType(filenameExtension: (fileName as NSString).pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
