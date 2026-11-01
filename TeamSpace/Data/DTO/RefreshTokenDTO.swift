import Foundation

/// POST /auth/refresh 요청
struct RefreshTokenRequestDTO: Codable {
    let refreshToken: String
}

/// POST /auth/refresh 응답 — 공통 형식 없이 바로 `{ accessToken, refreshToken }`
struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String

    func toEntity() -> AuthToken {
        AuthToken(accessToken: accessToken, refreshToken: refreshToken)
    }
}
