import Foundation

/// 가입 요청 관리 [Admin]
protocol SignupRequestRepository: Sendable {
    /// GET /admin/signup-requests — 최신순 (대기 · 승인 모두)
    func fetchSignupRequests(cursor: String?, limit: Int) async throws -> CursorPage<SignupRequestItem>
    /// POST /admin/signup-requests/{id}/approve — 초기 비밀번호를 비우면 요청할 때 정한 비밀번호를 써요.
    /// `memberId` 를 주면 조직도의 그 사람과 계정을 연결해요. (이미 연결된 사람이면 409)
    func approve(id: Int, temporaryPassword: String?, memberId: String?) async throws
    /// POST /admin/signup-requests/{id}/reject — 사유 필수, 대기 중인 요청만 (아니면 409)
    func reject(id: Int, reason: String) async throws
}
