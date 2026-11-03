import Foundation

/// GET /admin/finance/permissions 한 항목 · PATCH 응답 — `{ id, name?, email?, roles, canViewFinance }`
struct ServerFinancePermissionDTO: Decodable {
    let id: Int
    let name: String
    let email: String
    let roles: [UserRole]
    let canViewFinance: Bool

    private enum CodingKeys: String, CodingKey { case id, name, email, roles, canViewFinance }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        email = (try? container.decodeIfPresent(String.self, forKey: .email)) ?? ""
        roles = (try? container.decodeIfPresent([UserRole].self, forKey: .roles)) ?? []
        canViewFinance = (try? container.decodeIfPresent(Bool.self, forKey: .canViewFinance)) ?? false
    }

    func toEntity() -> FinancePermissionMember {
        FinancePermissionMember(id: id, name: name, email: email, roles: roles, canViewFinance: canViewFinance)
    }
}

/// PATCH /admin/finance/permissions/{userId} 요청
struct ServerFinancePermissionRequestDTO: Codable, Equatable {
    let canViewFinance: Bool
}
