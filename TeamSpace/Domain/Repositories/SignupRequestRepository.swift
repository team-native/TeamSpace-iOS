import Foundation

/// 가입 요청 관리 [Admin]
protocol SignupRequestRepository: Sendable {
    /// GET /admin/signup-requests — 최신순 (대기 · 승인 모두)
    func fetchSignupRequests(cursor: String?, limit: Int) async throws -> CursorPage<SignupRequestItem>
    /// POST /admin/signup-requests/{id}/approve — 초기 비밀번호를 비우면 요청할 때 정한 비밀번호를 써요.
    func approve(id: Int, temporaryPassword: String?) async throws
}
