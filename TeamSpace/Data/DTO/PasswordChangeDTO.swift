import Foundation

/// PATCH /me/settings 요청 — 비밀번호만 바꿔요. (서버는 테마 등 다른 설정도 같은 곳에서 받아요)
struct ServerPasswordChangeRequestDTO: Encodable, Equatable {
    let currentPassword: String
    let newPassword: String
}
