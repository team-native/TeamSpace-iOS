import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct Endpoint {
    let method: HTTPMethod
    /// 앞에 `/` 없이 씁니다. 예) "auth/login"
    let path: String
    var queryItems: [URLQueryItem] = []
    var body: Encodable?
    var requiresAuth: Bool = true
    /// 파일 올리기 — 있으면 `body` 대신 multipart/form-data 로 보내요.
    var file: MultipartFile?
}

/// multipart/form-data 의 파일 한 개 (서버 `UploadFile = File(...)`)
struct MultipartFile {
    var fieldName = "file"
    let filename: String
    let mimeType: String
    let data: Data

    func encoded(boundary: String) -> Data {
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }
}
