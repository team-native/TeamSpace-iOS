import Foundation

/// GET /admin/reports 한 항목 — `{ id, postId, reason, detail, status, handledBy?, handledAt?, note? }`
struct ServerReportItemDTO: Decodable {
    let id: Int
    let postId: Int
    let reason: String
    let detail: String
    let status: String
    let handledBy: String?
    let handledAt: Date?

    private enum CodingKeys: String, CodingKey { case id, postId, reason, detail, status, handledBy, handledAt }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        postId = try container.decodeIntOrString(forKey: .postId)
        reason = (try? container.decodeIfPresent(String.self, forKey: .reason)) ?? ""
        detail = (try? container.decodeIfPresent(String.self, forKey: .detail)) ?? ""
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "PENDING"
        handledBy = try? container.decodeIfPresent(String.self, forKey: .handledBy)
        handledAt = (try? container.decodeIfPresent(String.self, forKey: .handledAt)).flatMap { $0.flatMap(ServerDate.parse) }
    }

    func toEntity() -> PostReportItem {
        PostReportItem(
            id: id, postId: postId, reason: reason, detail: detail,
            status: PostReportStatus(serverValue: status), handledBy: handledBy, handledAt: handledAt, postTitle: nil
        )
    }
}

/// POST /admin/reports/{id}/decision 요청
struct ServerReportDecisionRequestDTO: Codable, Equatable {
    let decision: String
    let note: String
}
