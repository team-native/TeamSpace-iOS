import Foundation

/// 가입 요청 관리 한 줄 — GET /admin/signup-requests (서버는 비밀번호를 빼고 줘요)
struct SignupRequestItem: Equatable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
    /// 서버 `dept` (예: "Design")
    let department: String
    let major: String?
    let cohort: String?
    let message: String?
    var status: AccountRequestStatus
    let requestedAt: Date?
    var approvedBy: String?
}

