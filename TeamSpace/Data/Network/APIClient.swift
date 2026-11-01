import Foundation
import os

/// 요청 생성 · 토큰 첨부 · 공통 응답(`data`) 꺼내기 · 오류 변환을 담당합니다.
final class APIClient: @unchecked Sendable {
    private let baseURL: URL
    private let transport: HTTPTransport
    private let tokenStorage: TokenStorage
    private let logger = Logger(subsystem: AppLog.subsystem, category: "Network")

    init(baseURL: URL, transport: HTTPTransport, tokenStorage: TokenStorage) {
        self.baseURL = baseURL
        self.transport = transport
        self.tokenStorage = tokenStorage
    }

    func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let data = try await perform(endpoint)
        do {
            let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<Response>.self, from: data)
            guard let payload = envelope.data else { throw NetworkError.emptyData }
            return payload
        } catch let error as DecodingError {
            logger.error("decoding failed \(endpoint.path, privacy: .public): \(String(describing: error), privacy: .public)")
            throw NetworkError.decoding(error)
        }
    }

    private func perform(_ endpoint: Endpoint) async throws -> Data {
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
        if let body = endpoint.body {
            do {
                request.httpBody = try JSONCoder.makeEncoder().encode(body)
            } catch let error as EncodingError {
                throw NetworkError.encoding(error)
            }
        }
        return request
    }
}

enum JSONCoder {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
