import Foundation
import Observation

/// 07-14 설정 · 비밀번호 변경
@Observable
@MainActor
final class PasswordChangeViewModel {
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    private(set) var isSaving = false
    /// 바꾸고 나면 true → 완료 알림 후 화면을 닫아요.
    private(set) var didChange = false
    var errorMessage: String?

    private let changePasswordUseCase: ChangePasswordUseCase

    init(changePasswordUseCase: ChangePasswordUseCase) {
        self.changePasswordUseCase = changePasswordUseCase
    }

    var canSubmit: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty && !isSaving
    }

    /// 새 비밀번호 아래 안내 — 입력 중에 바로 알려줘요.
    var newPasswordHint: String? {
        guard !newPassword.isEmpty else { return nil }
        return newPassword.count < ChangePasswordUseCase.minimumLength ? "\(ChangePasswordUseCase.minimumLength)자 이상 입력해 주세요." : nil
    }

    var confirmHint: String? {
        guard !confirmPassword.isEmpty, confirmPassword != newPassword else { return nil }
        return "새 비밀번호와 같게 입력해 주세요."
    }

    func submit() async {
        guard canSubmit else { return }
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        do {
            try await changePasswordUseCase.execute(current: currentPassword, new: newPassword, confirm: confirmPassword)
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            didChange = true
        } catch {
            AppLog.record(error, context: "settings.password")
            errorMessage = error.userMessage
        }
    }
}
