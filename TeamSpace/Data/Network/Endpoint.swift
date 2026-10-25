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
}
