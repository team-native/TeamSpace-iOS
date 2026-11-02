import Foundation

/// 07-14 설정 · 비밀번호 변경 — 서버 규칙(8자 이상)에 확인 일치 · 현재와 다름을 더해 먼저 확인해요.
struct ChangePasswordUseCase {
    static let minimumLength = 8

    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    static func validationMessage(current: String, new: String, confirm: String) -> String? {
        if current.isEmpty { return "현재 비밀번호를 입력해 주세요." }
        if new.count < minimumLength { return "새 비밀번호는 \(minimumLength)자 이상이어야 해요." }
        if new == current { return "현재 비밀번호와 다른 비밀번호를 입력해 주세요." }
        if new != confirm { return "새 비밀번호가 서로 달라요." }
        return nil
    }

    func execute(current: String, new: String, confirm: String) async throws {
        if let message = Self.validationMessage(current: current, new: new, confirm: confirm) {
            throw AppError.invalidInput(message)
        }
        try await workspaceRepository.changePassword(current: current, new: new)
    }
}
