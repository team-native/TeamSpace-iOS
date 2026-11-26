import Foundation

extension ServerPersonDTO {
    /// 멤버 관리 화면용 — `linked` 가 없는 옛 응답은 모두 계정으로 봐요.
    func toManagedMember() -> ManagedMember {
        let organizationId = id.hasPrefix("member-") ? id : nil
        let hasAccount = linked == nil || userId != nil
        return ManagedMember(
            id: userId ?? id,
            organizationId: organizationId,
            name: name,
            email: email,
            department: dept,
            roles: roles,
            isActive: active ?? true,
            hasAccount: hasAccount,
            isLinked: linked ?? false
        )
    }
}

/// GET /admin/users 한 사람 — Admin · 꺼진 계정까지 모든 계정이 와요.
/// `{ id, userId, memberId, name, email, dept, roles, active, inOrganization, isAdmin, createdAt }`
struct ServerAdminUserDTO: Decodable {
    let userId: String
    let memberId: String?
    let name: String
    let email: String
    let dept: String
    let roles: [UserRole]
    let active: Bool
    let inOrganization: Bool

    private enum CodingKeys: String, CodingKey { case id, userId, memberId, name, email, dept, roles, active, inOrganization }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userId = (try? container.decodeStringOrInt(forKey: .userId)) ?? ""
        self.userId = userId.isEmpty ? try container.decodeStringOrInt(forKey: .id) : userId
        memberId = (try? container.decodeIfPresent(String.self, forKey: .memberId)) ?? nil
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        email = (try? container.decodeIfPresent(String.self, forKey: .email)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        roles = (try? container.decodeIfPresent([UserRole].self, forKey: .roles)) ?? []
        active = (try? container.decodeIfPresent(Bool.self, forKey: .active)) ?? true
        inOrganization = (try? container.decodeIfPresent(Bool.self, forKey: .inOrganization)) ?? false
    }

    /// 조직도에 있는 사람만 조직도 id 를 들고, 그 밖의 `member-25` 같은 id 는 연결로 보지 않아요.
    func toManagedMember() -> ManagedMember {
        ManagedMember(
            id: userId,
            organizationId: inOrganization ? memberId : nil,
            name: name,
            email: email,
            department: dept,
            roles: roles,
            isActive: active,
            hasAccount: true,
            isLinked: inOrganization
        )
    }
}

/// PATCH /admin/users/{id}/roles 요청 · 응답
struct ServerUserRolesDTO: Codable, Equatable {
    let roles: [String]
}

/// PATCH /admin/users/{id} 요청 — 바꿀 값만 보내요. (nil 이면 키를 빼요)
struct ServerAdminUserPatchDTO: Encodable, Equatable {
    var active: Bool?
    var dept: String?
    var memberId: String?
}

/// POST /admin/users 요청
struct ServerAdminUserCreateDTO: Encodable, Equatable {
    let name: String
    let email: String
    let dept: String?
    let roles: [String]
}

/// POST /admin/users 응답 — `{ id, name, email, dept, roles, temporaryPassword }`
struct ServerAdminUserCreatedDTO: Decodable {
    let id: String
    let name: String
    let email: String
    let dept: String
    let roles: [UserRole]
    let temporaryPassword: String

    private enum CodingKeys: String, CodingKey { case id, name, email, dept, roles, temporaryPassword }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeStringOrInt(forKey: .id)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        email = (try? container.decodeIfPresent(String.self, forKey: .email)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        roles = (try? container.decodeIfPresent([UserRole].self, forKey: .roles)) ?? []
        temporaryPassword = try container.decode(String.self, forKey: .temporaryPassword)
    }

    func toEntity() -> CreatedMember {
        CreatedMember(
            member: ManagedMember(
                id: id, organizationId: id.hasPrefix("member-") ? id : nil, name: name, email: email, department: dept,
                roles: roles, isActive: true, hasAccount: true, isLinked: id.hasPrefix("member-")
            ),
            temporaryPassword: temporaryPassword
        )
    }
}
