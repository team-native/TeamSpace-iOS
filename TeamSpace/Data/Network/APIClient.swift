import Foundation
import os

/// 요청 생성 · 토큰 첨부 · 공통 응답(`data`) 꺼내기 · 토큰 갱신 · 오류 변환을 담당합니다.
final class APIClient: @unchecked Sendable {
    private let baseURL: URL
    private let transport: HTTPTransport
    private let tokenStorage: TokenStorage
    private let refresher = TokenRefresher()
    private let logger = Logger(subsystem: AppLog.subsystem, category: "Network")
    private let lock = NSLock()
    private var sessionExpiredHandler: (@Sendable () -> Void)?

    init(baseURL: URL, transport: HTTPTransport, tokenStorage: TokenStorage) {
        self.baseURL = baseURL
        self.transport = transport
        self.tokenStorage = tokenStorage
    }

    /// 리프레시 토큰까지 만료돼 토큰을 지웠을 때 불러요. (AppSession 이 로그인 화면으로 보냄)
    func setSessionExpiredHandler(_ handler: (@Sendable () -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        sessionExpiredHandler = handler
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let data = try await perform(endpoint)
        do {
            return try Self.decodePayload(Response.self, from: data)
        } catch let error as DecodingError {
            logger.error("decoding failed \(endpoint.path, privacy: .public): \(String(describing: error), privacy: .public)")
            throw NetworkError.decoding(error)
        }
    }

    /// 공통 형식이면 `data` 를 꺼내고, 아니면(`/auth/login` · `/auth/refresh` · `/users/me`) 응답 전체를 그대로 읽어요.
    static func decodePayload<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        let decoder = JSONCoder.makeDecoder()
        guard (try? decoder.decode(APIEnvelopeProbe.self, from: data)) != nil else {
            return try decoder.decode(Response.self, from: data)
        }
        let envelope = try decoder.decode(APIResponseDTO<Response>.self, from: data)
        guard let payload = envelope.data else { throw NetworkError.emptyData }
        return payload
    }

    /// 액세스 토큰 만료(401)면 한 번 갱신하고 같은 요청을 다시 보내요.
    private func perform(_ endpoint: Endpoint) async throws -> Data {
        let usedToken = endpoint.requiresAuth ? tokenStorage.load() : nil
        do {
            return try await send(endpoint)
        } catch NetworkError.status(let code, let body) where code == 401 && usedToken != nil {
            guard let usedToken else { throw NetworkError.status(code: code, body: body) }
            try await refreshToken(replacing: usedToken)
            return try await send(endpoint)
        }
    }

    private func refreshToken(replacing usedToken: AuthToken) async throws {
        // 그사이 다른 요청이 이미 갱신했으면 새 토큰으로 다시 보내기만 해요.
        guard let current = tokenStorage.load() else { throw NetworkError.status(code: 401, body: nil) }
        guard current.accessToken == usedToken.accessToken else { return }
        do {
            _ = try await refresher.refresh { [self] in
                let data = try await send(Endpoint(
                    method: .post,
                    path: "auth/refresh",
                    body: RefreshTokenRequestDTO(refreshToken: current.refreshToken),
                    requiresAuth: false
                ))
                let token = try Self.decodePayload(RefreshTokenResponseDTO.self, from: data).toEntity()
                try tokenStorage.update(token)
                return token
            }
        } catch NetworkError.status(let code, let body) where code == 401 {
            expireSession()
            throw NetworkError.status(code: code, body: body)
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        }
    }

    private func expireSession() {
        logger.notice("refresh token expired — signing out")
        try? tokenStorage.clear()
        lock.lock()
        let handler = sessionExpiredHandler
        lock.unlock()
        handler?()
    }

    private func send(_ endpoint: Endpoint) async throws -> Data {
        let request = try makeRequest(endpoint)
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as URLError {
            logger.error("transport \(endpoint.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw NetworkError.transport(error)
        }
        guard (200..<300).contains(response.statusCode) else {
            let body = try? JSONCoder.makeDecoder().decode(APIErrorResponseDTO.self, from: data)
            logger.notice("status \(response.statusCode) \(endpoint.path, privacy: .public)")
            throw NetworkError.status(code: response.statusCode, body: body)
        }
        return data
    }

    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if endpoint.requiresAuth, let token = tokenStorage.load() {
            request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let file = endpoint.file {
            let boundary = "TeamSpace-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = file.encoded(boundary: boundary)
        } else if let body = endpoint.body {
            do {
                request.httpBody = try JSONCoder.makeEncoder().encode(body)
            } catch let error as EncodingError {
                throw NetworkError.encoding(error)
            }
        }
        return request
    }
}

/// 여러 요청이 동시에 401 을 받아도 갱신 요청은 한 번만 보내요.
private actor TokenRefresher {
    private var inFlight: Task<AuthToken, Error>?

    func refresh(_ operation: @escaping @Sendable () async throws -> AuthToken) async throws -> AuthToken {
        if let inFlight { return try await inFlight.value }
        let task = Task { try await operation() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

enum JSONCoder {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = ServerDate.parse(text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "날짜 형식이 아니에요: \(text)")
            }
            return date
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
