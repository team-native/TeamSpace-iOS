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

    func fetchRecruitment(projectId: Int) async throws -> RecruitmentPost {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/recruitment"), as: RecruitmentDTO.self).toEntity()
    }

    func apply(projectId: Int, draft: ApplicationDraft) async throws -> ProjectApplication {
        let endpoint = Endpoint(method: .post, path: "projects/\(projectId)/apply", body: ApplyRequestDTO(draft))
        return try await request(endpoint, as: ApplicationDTO.self).toEntity()
    }

    func fetchMyApplications() async throws -> [ProjectApplication] {
        try await request(Endpoint(method: .get, path: "applications/mine"), as: ApplicationListResponseDTO.self)
            .list.map { $0.toEntity() }
    }

    func cancelApplication(id: Int) async throws {
        do {
            _ = try await client.request(Endpoint(method: .delete, path: "applications/\(id)"), as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    func fetchApplicants(projectId: Int) async throws -> ApplicantBoard {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/applicants"), as: ApplicantBoardDTO.self).toEntity()
    }

    func decide(projectId: Int, applicantId: Int, decision: ApplicantDecision, reason: String) async throws -> Applicant {
        let endpoint = Endpoint(
            method: .post,
            path: "projects/\(projectId)/applicants/\(applicantId)/decision",
            body: ApplicantDecisionRequestDTO(decision: decision.rawValue, reason: reason)
        )
        return try await request(endpoint, as: ApplicantDTO.self).toEntity()
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
