import Foundation

/// POST /auth/login 응답 — 서버(develop)는 공통 형식 없이 바로 `{ accessToken, refreshToken, user { id: "1", name, roles } }`
///
/// 예전 명세서의 평평한 형태(`userId · userName · userRoles`)도 받습니다.
struct LoginResponseDTO: Decodable {
    struct UserDTO: Decodable {
        let id: Int
        let name: String
        let roles: [UserRole]

        init(id: Int, name: String, roles: [UserRole]) {
            self.id = id
            self.name = name
            self.roles = roles
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIntOrString(forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            roles = try container.decode([UserRole].self, forKey: .roles)
        }

        private enum CodingKeys: String, CodingKey {
            case id, name, roles
        }
    }

    let accessToken: String
    let refreshToken: String
    let user: UserDTO

    private enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, user, userId, userName, userRoles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        if let nested = try container.decodeIfPresent(UserDTO.self, forKey: .user) {
            user = nested
        } else {
            user = UserDTO(
                id: try container.decodeIntOrString(forKey: .userId),
                name: try container.decode(String.self, forKey: .userName),
                roles: try container.decode([UserRole].self, forKey: .userRoles)
            )
        }
    }

    func toEntity() -> AuthSession {
        AuthSession(
            token: AuthToken(accessToken: accessToken, refreshToken: refreshToken),
            user: AuthUser(id: user.id, name: user.name, roles: user.roles)
        )
    }
}
