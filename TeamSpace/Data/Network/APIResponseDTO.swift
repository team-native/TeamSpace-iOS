import Foundation

/// 서버 공통 응답 형식 `{ code, message, data }`
struct APIResponseDTO<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let data: T?
}

/// 서버 오류 형식 — 명세서 `{ code, message, errors: [{ field, reason }] }`,
/// 실제 서버(FastAPI)는 `{ "detail": "메시지" }` (입력 검증 422 는 `detail` 이 배열)
struct APIErrorResponseDTO: Decodable {
    struct FieldErrorDTO: Decodable {
        let field: String
        let reason: String
    }

    let code: Int?
    let message: String?
    let errors: [FieldErrorDTO]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try? container.decodeIfPresent(Int.self, forKey: .code)
        errors = try? container.decodeIfPresent([FieldErrorDTO].self, forKey: .errors)
        let detail = try? container.decodeIfPresent(String.self, forKey: .detail)
        message = (try? container.decodeIfPresent(String.self, forKey: .message)) ?? detail
    }

    private enum CodingKeys: String, CodingKey {
        case code, message, errors, detail
    }
}

/// 공통 형식(`{ code, data }`)인지 알아보는 용도 — 정수 `code` 가 있으면 공통 형식으로 봐요.
struct APIEnvelopeProbe: Decodable {
    let code: Int
}
