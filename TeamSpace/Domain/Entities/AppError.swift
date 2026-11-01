import Foundation

/// 앱 전역 에러. 사용자에게 보여줄 메시지(`userMessage`)와 개발자용 정보(`debugInfo`)를 구분합니다.
enum AppError: Error, Equatable {
    /// 400 — 입력값 오류 (서버가 내려준 사유)
    case invalidInput(String)
    /// 로그인 401 — 이메일 또는 비밀번호 불일치
    case invalidCredentials
    /// 401 — 토큰 만료 · 미인증
    case unauthorized(String?)
    /// 403 — 권한 없음
    case forbidden(String?)
    /// 404
    case notFound(String?)
    case network
    case server(statusCode: Int)
    case decoding(String)
    case unknown(String)

    var userMessage: String {
        switch self {
        case .invalidInput(let message):
            return message
        case .invalidCredentials:
            return "이메일 또는 비밀번호를 다시 확인해 주세요."
        case .unauthorized(let message):
            return message ?? "로그인이 만료됐어요. 다시 로그인해 주세요."
        case .forbidden(let message):
            return message ?? "이 정보를 볼 수 있는 권한이 없어요."
        case .notFound(let message):
            return message ?? "요청한 정보를 찾을 수 없어요."
        case .network:
            return "네트워크 연결을 확인해 주세요."
        case .server, .decoding, .unknown:
            return "잠시 후 다시 시도해 주세요."
        }
    }

    var debugInfo: String {
        switch self {
        case .server(let statusCode):
            return "server error status=\(statusCode)"
        case .decoding(let detail):
            return "decoding failed: \(detail)"
        case .unknown(let detail):
            return "unknown: \(detail)"
        default:
            return String(describing: self)
        }
    }
}
