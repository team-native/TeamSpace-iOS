import Foundation

/// GET /users/me 응답의 `data`
struct UserMeResponseDTO: Decodable {
    let id: Int
    let name: String
    let email: String
    let department: Department
    let roles: [UserRole]

    func toEntity() -> AuthUser {
        AuthUser(id: id, name: name, roles: roles)
    }
}
