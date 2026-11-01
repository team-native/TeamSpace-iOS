import Foundation

enum NetworkError: Error {
    case invalidURL
    case transport(URLError)
    case status(code: Int, body: APIErrorResponseDTO?)
    case emptyData
    case decoding(DecodingError)
    case encoding(EncodingError)

    /// Domain 으로 넘길 때는 AppError 로 바꿉니다. 서버 메시지가 있으면 사용자 메시지로 씁니다.
    var asAppError: AppError {
        switch self {
        case .invalidURL:
            return .unknown("invalid url")
        case .transport:
            return .network
        case .status(let code, let body):
            let message = body?.message
            switch code {
            case 400:
                let reason = body?.errors?.first?.reason ?? message ?? "입력한 정보를 다시 확인해 주세요."
                return .invalidInput(reason)
            case 401: return .unauthorized(message)
            case 403: return .forbidden(message)
            case 404: return .notFound(message)
            case 409: return .conflict(message)
            default: return .server(statusCode: code)
            }
        case .emptyData:
            return .decoding("empty data")
        case .decoding(let error):
            return .decoding(String(describing: error))
        case .encoding(let error):
            return .unknown(String(describing: error))
        }
    }
}
