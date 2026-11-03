import Foundation

final class ProjectRepositoryImpl: ProjectRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// 100건씩, 최대 5페이지
    func fetchProjects() async throws -> [ProjectSummary] {
        var projects: [ProjectSummary] = []
        var cursor: String?
        for _ in 0..<5 {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "projects", queryItems: query), as: ServerProjectPageDTO.self)
            projects += page.items.map { $0.toEntity() }
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return projects
    }

    /// 참여 여부는 서버 상세에 없어 /me/projects 와 비교해요. (실패하면 미참여)
    func fetchProjectDetail(id: String) async throws -> ProjectDetail {
        async let detailRequest = request(Endpoint(method: .get, path: "projects/\(id)"), as: ServerProjectDTO.self)
        async let mineRequest = request(Endpoint(method: .get, path: "me/projects"), as: CursorPageDTO<ServerMyProjectRefDTO>.self)
        let project = try await detailRequest
        let mine = (try? await mineRequest)?.items ?? []
        return project.toDetail(isJoined: mine.contains { $0.matches(project) })
    }

    func createProject(_ draft: ProjectDraft) async throws -> String {
        let body = ServerProjectWriteRequestDTO(draft)
        return try await request(Endpoint(method: .post, path: "admin/projects", body: body), as: ServerProjectCreatedDTO.self).slug
    }

    func updateProject(id: String, _ draft: ProjectDraft) async throws {
        let body = ServerProjectWriteRequestDTO(draft)
        _ = try await request(Endpoint(method: .patch, path: "admin/projects/\(id)", body: body), as: EmptyResponseDTO.self)
    }

    func updateOpenings(projectId: String, _ openings: [OpeningDraft]) async throws {
        let body = ServerProjectOpeningsRequestDTO(openings)
        _ = try await request(Endpoint(method: .patch, path: "admin/projects/\(projectId)", body: body), as: EmptyResponseDTO.self)
    }

    func fetchTimeline(projectId: String) async throws -> ProjectTimeline {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/schedule"), as: ProjectTimelineDTO.self).toEntity()
    }

    func fetchRecruitment(projectId: String) async throws -> RecruitmentPost {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/recruitment"), as: RecruitmentDTO.self).toEntity()
    }

    /// 서버는 신청 번호만 돌려줘서 보낸 내용으로 신청을 만들어요.
    func apply(projectId: String, draft: ApplicationDraft) async throws -> ProjectApplication {
        let endpoint = Endpoint(method: .post, path: "projects/\(projectId)/apply", body: ServerApplyRequestDTO(draft))
        let result = try await request(endpoint, as: ServerApplyResultDTO.self)
        return ProjectApplication(
            id: result.applicationId, projectId: projectId, projectName: "", role: draft.position, department: "",
            status: .submitted, appliedAt: Date(), headcount: 1, pmName: "", message: draft.message, portfolioUrl: nil,
            reviewedAt: nil, resultDueDate: nil, decidedAt: nil, resultReason: nil
        )
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

    func fetchApplicants(projectId: String) async throws -> ApplicantBoard {
        try await request(Endpoint(method: .get, path: "projects/\(projectId)/applicants"), as: ApplicantBoardDTO.self).toEntity()
    }

    func decide(projectId: String, applicantId: Int, decision: ApplicantDecision, reason: String) async throws -> Applicant {
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
