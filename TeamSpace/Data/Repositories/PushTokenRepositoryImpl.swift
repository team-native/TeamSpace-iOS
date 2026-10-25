import Foundation

final class PushTokenRepositoryImpl: PushTokenRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// POST /notifications/push-token
    func register(token: String) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "notifications/push-token",
            body: PushTokenRequestDTO(token: token)
        )
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
