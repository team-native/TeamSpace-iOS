import Foundation

/// 가입 요청 목록 — Admin 만
struct FetchSignupRequestsUseCase {
    static let pageLimit = 100

    private let signupRequestRepository: SignupRequestRepository

    init(signupRequestRepository: SignupRequestRepository) {
        self.signupRequestRepository = signupRequestRepository
    }

    func execute(user: AuthUser) async throws -> [SignupRequestItem] {
        guard user.can(.approveSignups) else { throw AppError.forbidden("가입 요청은 관리자만 볼 수 있어요.") }
        return try await signupRequestRepository.fetchSignupRequests(cursor: nil, limit: Self.pageLimit).items
    }
}

/// 가입 요청 승인 — Admin 만, 검토 중인 요청만. 초기 비밀번호는 비우거나 8자 이상
struct ApproveSignupRequestUseCase {
    static let passwordMinLength = 8

    private let signupRequestRepository: SignupRequestRepository

    init(signupRequestRepository: SignupRequestRepository) {
        self.signupRequestRepository = signupRequestRepository
    }

    func execute(_ request: SignupRequestItem, temporaryPassword: String, memberId: String? = nil, user: AuthUser) async throws -> SignupRequestItem {
        guard user.can(.approveSignups) else { throw AppError.forbidden("가입 요청은 관리자만 승인할 수 있어요.") }
        guard request.status == .reviewing else { throw AppError.invalidInput("이미 처리한 요청이에요.") }
        let password = temporaryPassword.trimmingCharacters(in: .whitespaces)
        guard password.isEmpty || password.count >= Self.passwordMinLength else {
            throw AppError.invalidInput("초기 비밀번호는 \(Self.passwordMinLength)자 이상으로 정해 주세요.")
        }
        try await signupRequestRepository.approve(id: request.id, temporaryPassword: password.isEmpty ? nil : password, memberId: memberId)
        var approved = request
        approved.status = .approved
        approved.approvedBy = user.name
        return approved
    }
}

/// 가입 요청 반려 — Admin 만, 검토 중인 요청만, 사유 필수
struct RejectSignupRequestUseCase {
    static let reasonLimit = 2_000

    private let signupRequestRepository: SignupRequestRepository

    init(signupRequestRepository: SignupRequestRepository) {
        self.signupRequestRepository = signupRequestRepository
    }

    func execute(_ request: SignupRequestItem, reason: String, user: AuthUser) async throws -> SignupRequestItem {
        guard user.can(.approveSignups) else { throw AppError.forbidden("가입 요청은 관리자만 반려할 수 있어요.") }
        guard request.status == .reviewing else { throw AppError.invalidInput("이미 처리한 요청이에요.") }
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.invalidInput("반려 사유를 적어 주세요.") }
        guard trimmed.count <= Self.reasonLimit else {
            throw AppError.invalidInput("반려 사유는 \(TSFormat.number(Self.reasonLimit))자까지 적을 수 있어요.")
        }
        try await signupRequestRepository.reject(id: request.id, reason: trimmed)
        var rejected = request
        rejected.status = .rejected
        rejected.rejectionReason = trimmed
        rejected.rejectedBy = user.name
        return rejected
    }
}

/// 승인할 때 연결할 수 있는 조직도 구성원 — 계정이 아직 없는 사람만, 이름순
struct FetchLinkableMembersUseCase {
    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func execute() async throws -> [Member] {
        try await memberRepository.fetchMembers()
            .filter(\.needsAccount)
            .sorted { $0.name < $1.name }
    }
}
