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
}
