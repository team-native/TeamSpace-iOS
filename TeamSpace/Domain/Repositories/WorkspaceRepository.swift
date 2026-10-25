import Foundation

/// 내 공간 저장소
/// 명세서에는 `GET /workspace/todos` 만 있어 대시보드 요약 경로는 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol WorkspaceRepository: Sendable {
    /// GET /workspace/home — 07-1 내 공간 대시보드 요약
    func fetchHome() async throws -> WorkspaceHome
}
