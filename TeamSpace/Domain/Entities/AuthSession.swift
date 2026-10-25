import Foundation

struct AuthToken: Equatable {
    let accessToken: String
    let refreshToken: String
}

/// 서버 역할 값. 모르는 값은 `.unknown` 으로 받아요.
enum UserRole: String, UnknownCaseDecodable, Hashable {
    case member = "Member"
    case pm = "PM"
    case leader = "Leader"
    case fa = "FA"
    case admin = "Admin"
    case unknown = "UNKNOWN"

    static let unknownCase: UserRole = .unknown
}

struct AuthUser: Equatable {
    let id: Int
    let name: String
    let roles: [UserRole]
}

/// 로그인 결과
struct AuthSession: Equatable {
    let token: AuthToken
    let user: AuthUser
}
