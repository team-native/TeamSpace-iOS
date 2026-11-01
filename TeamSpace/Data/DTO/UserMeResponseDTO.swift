import Foundation

/// GET /users/me 응답 — 서버(develop)는 공통 형식 없이 바로 내려와요. 부서가 아직 없으면 `department: null`
struct UserMeResponseDTO: Decodable {
    let id: Int
    let name: String
    let email: String
    let department: Department?
    let roles: [UserRole]

    func toEntity() -> AuthUser {
        AuthUser(id: id, name: name, roles: roles)
    }
}
