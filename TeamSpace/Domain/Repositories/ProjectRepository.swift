import Foundation

/// 프로젝트 저장소 — 목록 · 상세 · 참여 신청은 TeamSpace-backend `space.py`, 나머지는 서버에 아직 없어요. (백엔드와 맞춰야 함)
/// 프로젝트 id 는 서버 slug (예: "book-on") 또는 숫자 문자열이에요.
protocol ProjectRepository: Sendable {
    /// GET /projects — 프로젝트 목록
    func fetchProjects() async throws -> [ProjectSummary]
    /// GET /projects/{id} — 프로젝트 상세 및 참여자 (+ /me/projects 로 참여 여부)
    func fetchProjectDetail(id: String) async throws -> ProjectDetail
    /// GET /projects/{id}/schedule — 08-8 일정과 변경 이력 (서버에 없음)
    func fetchTimeline(projectId: String) async throws -> ProjectTimeline
    /// GET /projects/{id}/recruitment — 08-3 모집 공고 (서버에 없음)
    func fetchRecruitment(projectId: String) async throws -> RecruitmentPost
    /// POST /projects/{id}/apply — 08-4 참여 신청
    func apply(projectId: String, draft: ApplicationDraft) async throws -> ProjectApplication
    /// GET /applications/mine — 08-6 내 참여 신청 (서버에 없음)
    func fetchMyApplications() async throws -> [ProjectApplication]
    /// DELETE /applications/{applicationId} — 신청 취소 (서버에 없음)
    func cancelApplication(id: Int) async throws
    /// GET /projects/{id}/applicants — 08-7 지원자 목록 (PM · Admin, 서버에 없음)
    func fetchApplicants(projectId: String) async throws -> ApplicantBoard
    /// POST /projects/{id}/applicants/{applicantId}/decision — 참여 확정 · 미선정 (서버에 없음)
    func decide(projectId: String, applicantId: Int, decision: ApplicantDecision, reason: String) async throws -> Applicant
    /// POST /admin/projects — 프로젝트 등록 (Admin). 새 프로젝트 id(slug)를 돌려줘요.
    func createProject(_ draft: ProjectDraft) async throws -> String
    /// PATCH /admin/projects/{id} — 기본 정보 수정 (Admin). 참여자 · 모집은 그대로예요.
    func updateProject(id: String, _ draft: ProjectDraft) async throws
    /// PATCH /admin/projects/{id} `{openings}` — 모집 자리 전체를 바꿔요. (Admin)
    func updateOpenings(projectId: String, _ openings: [OpeningDraft]) async throws
}
