import Foundation

/// GET /admin/signup-requests 한 항목 — `{ id, email, name, dept, major?, cohort?, message?, status, createdAt, approvedBy? }`
struct ServerSignupRequestDTO: Decodable {
    let id: Int
    let email: String
    let name: String
    let dept: String
    let major: String?
    let cohort: String?
    let message: String?
    let status: String
    let createdAt: Date?
    let approvedBy: String?

    private enum CodingKeys: String, CodingKey { case id, email, name, dept, major, cohort, message, status, createdAt, approvedBy }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        email = (try? container.decodeIfPresent(String.self, forKey: .email)) ?? ""
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        func optional(_ key: CodingKeys) -> String? {
            guard let value = (try? container.decodeIfPresent(String.self, forKey: key)) ?? nil else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        major = optional(.major)
        cohort = optional(.cohort)
        message = optional(.message)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "PENDING"
        createdAt = optional(.createdAt).flatMap(ServerDate.parse)
        approvedBy = optional(.approvedBy)
    }

    func toEntity() -> SignupRequestItem {
        SignupRequestItem(
            id: id, name: name, email: email, department: dept, major: major, cohort: cohort, message: message,
            status: AccountRequestStatus(serverValue: status), requestedAt: createdAt, approvedBy: approvedBy
        )
    }
}

/// POST /admin/signup-requests/{id}/approve 요청 — 비우면 키를 빼요.
struct ServerSignupApproveRequestDTO: Codable, Equatable {
    let temporaryPassword: String?
}
