import Foundation

/// 서버 공통 응답 형식 `{ code, message, data }`
struct APIResponseDTO<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let data: T?
}

/// 서버 공통 오류 형식 `{ code, message, errors: [{ field, reason }] }`
struct APIErrorResponseDTO: Decodable {
    struct FieldErrorDTO: Decodable {
        let field: String
        let reason: String
    }

    let code: Int?
    let message: String?
    let errors: [FieldErrorDTO]?
}
