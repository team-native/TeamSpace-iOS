import Foundation

/// 서버 없이 개발하기 위한 가짜 서버. 명세서의 응답 예시를 그대로 돌려줍니다.
/// - 비밀번호 `wrong` → 401 (계정 불일치)
/// - 이메일 형식 오류 → 400 (errors[].reason)
/// - 그 외 → 200 로그인 성공
/// - GET /users/me: Authorization 헤더가 없으면 401
/// - 계정 요청: 이메일이 `taken@` 으로 시작하면 409 (이미 요청됨)
struct MockTransport: HTTPTransport {
    static let baseURL = URL(fileURLWithPath: "/mock-api")
    static let failingPassword = "wrong"

    var latencyNanoseconds: UInt64 = 700_000_000

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await Task.sleep(nanoseconds: latencyNanoseconds)
        let path = request.url?.lastPathComponent ?? ""
        switch (request.httpMethod, path) {
        case ("POST", "login"):
            return try login(request)
        case ("POST", "account-requests"):
            return try accountRequest(request)
        case ("GET", "me"):
            return try me(request)
        case ("POST", "password-reset"):
            return try respond(request, status: 200, json: #"{"code":200,"message":"메일 발송 완료","data":{"success":true}}"#)
        default:
            return try respond(request, status: 404, json: #"{"code":404,"message":"Mock 에 없는 API 입니다."}"#)
        }
    }

    private func login(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(LoginRequestDTO.self, from: body)
        else {
            return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청 파라미터입니다."}"#)
        }
        if !dto.email.contains("@") {
            return try respond(request, status: 400, json: """
            {"code":400,"message":"잘못된 요청 파라미터입니다.","errors":[{"field":"email","reason":"이메일 형식이 올바르지 않습니다."}]}
            """)
        }
        if dto.password == Self.failingPassword {
            return try respond(request, status: 401, json: #"{"code":401,"message":"이메일 또는 비밀번호가 일치하지 않습니다."}"#)
        }
        return try respond(request, status: 200, json: """
        {"code":200,"message":"로그인 성공","data":{"accessToken":"mock-access-token","refreshToken":"mock-refresh-token",\
        "user":{"id":1,"name":"홍길동","roles":["Member"]}}}
        """)
    }

    private func me(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            return try respond(request, status: 401, json: #"{"code":401,"message":"유효하지 않거나 만료된 토큰입니다. 로그인해 주세요."}"#)
        }
        return try respond(request, status: 200, json: """
        {"code":200,"message":"조회 성공","data":{"id":1,"name":"홍길동","email":"s00000@gsm.hs.kr",\
        "department":"NativeOps","roles":["Member","PM"]}}
        """)
    }

    private func accountRequest(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(AccountRequestRequestDTO.self, from: body)
        else {
            return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청 파라미터입니다."}"#)
        }
        if dto.email.hasPrefix("taken@") {
            return try respond(request, status: 409, json: #"{"code":409,"message":"이미 요청된 이메일입니다."}"#)
        }
        let payload = MockEnvelope(
            code: 201,
            message: "요청 완료",
            data: MockAccountRequestData(
                name: dto.name,
                email: dto.email,
                department: dto.department,
                status: "REVIEWING",
                requestedAt: ISO8601DateFormatter().string(from: Date())
            )
        )
        let data = try JSONEncoder().encode(payload)
        return try respond(request, status: 201, json: String(decoding: data, as: UTF8.self))
    }

    private func respond(_ request: URLRequest, status: Int, json: String) throws -> (Data, HTTPURLResponse) {
        guard
            let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else {
            throw URLError(.badURL)
        }
        return (Data(json.utf8), response)
    }
}

private struct MockEnvelope<T: Encodable>: Encodable {
    let code: Int
    let message: String
    let data: T
}

private struct MockAccountRequestData: Encodable {
    let name: String
    let email: String
    let department: String
    let status: String
    let requestedAt: String
}
