import Foundation

/// 프로젝트 저장소
/// 명세서 경로를 쓰지만 응답 예시가 없어 필드는 Figma 08 기준으로 정했습니다. (백엔드와 맞춰야 함)
protocol ProjectRepository: Sendable {
    /// GET /projects — 프로젝트 목록 (명세서)
    func fetchProjects() async throws -> [ProjectSummary]
    /// GET /projects/{projectId} — 프로젝트 상세 및 참여자 (명세서)
    func fetchProjectDetail(id: Int) async throws -> ProjectDetail
    /// GET /projects/{projectId}/schedule — 08-8 일정과 변경 이력 (명세서에 없음)
    func fetchTimeline(projectId: Int) async throws -> ProjectTimeline
    /// GET /projects/{projectId}/recruitment — 08-3 모집 공고 (명세서에 없음)
    func fetchRecruitment(projectId: Int) async throws -> RecruitmentPost
    /// POST /projects/{projectId}/apply — 08-4 참여 신청 (명세서)
    func apply(projectId: Int, draft: ApplicationDraft) async throws -> ProjectApplication
    /// GET /applications/mine — 08-6 내 참여 신청 (명세서에 없음)
    func fetchMyApplications() async throws -> [ProjectApplication]
    /// DELETE /applications/{applicationId} — 신청 취소 (명세서에 없음)
    func cancelApplication(id: Int) async throws
    /// GET /projects/{projectId}/applicants — 08-7 지원자 목록 (PM · Admin, 명세서에 없음)
    func fetchApplicants(projectId: Int) async throws -> ApplicantBoard
    /// POST /projects/{projectId}/applicants/{applicantId}/decision — 참여 확정 · 미선정 (명세서에 없음)
    func decide(projectId: Int, applicantId: Int, decision: ApplicantDecision, reason: String) async throws -> Applicant
}
