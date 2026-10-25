import Foundation

final class ProjectRepositoryImpl: ProjectRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchProjects() async throws -> [ProjectSummary] {
        try await request(Endpoint(method: .get, path: "projects"), as: ProjectListResponseDTO.self).list.map { $0.toEntity() }
    }

    func fetchProjectDetail(id: Int) async throws -> ProjectDetail {
        try await request(Endpoint(method: .get, path: "projects/\(id)"), as: ProjectDetailDTO.self).toEntity()
    }

    func fetchTimeline(projectId: Int) async throws -> ProjectTimeline {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/schedule"), as: ProjectTimelineDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
