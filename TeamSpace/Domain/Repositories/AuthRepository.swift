import Foundation

protocol AuthRepository: Sendable {
    /// POST /auth/login
    func login(_ credential: LoginCredential) async throws -> AuthSession
    /// GET /users/me — 저장된 토큰으로 내 정보 조회 (자동 로그인)
    func fetchMe() async throws -> AuthUser
    /// 계정 요청 — API 명세서에 아직 없음 (백엔드 추가 요청 필요)
    func requestAccount(_ form: AccountRequestForm) async throws -> AccountRequestReceipt
    /// 비밀번호 재설정 메일 — API 명세서에 아직 없음 (백엔드 추가 요청 필요)
    func requestPasswordReset(email: String) async throws
}
