import Foundation

/// POST /auth/login 응답의 `data`
///
/// 명세서의 응답 표는 `userId · userName · userRoles` (평평한 형태),
/// 예시 JSON 은 `user { id, name, roles }` (묶인 형태)라서 두 형태를 모두 받습니다.
/// TODO: 백엔드와 형태 확정 후 하나로 정리
struct LoginResponseDTO: Decodable {
    struct UserDTO: Decodable {
        let id: Int
        let name: String
        let roles: [UserRole]
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
                id: try container.decode(Int.self, forKey: .userId),
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
