import Foundation
import Observation

enum PasswordRuleState {
    case idle
    case valid
    case invalid
}

/// 01-2 인하우스 계정 요청
@Observable
@MainActor
final class AccountRequestViewModel {
    var form = AccountRequestForm()
    /// 01-5 소속 부서 선택 카드 표시 여부
    var isDepartmentPickerPresented = false
    private(set) var submitState: ViewState<AccountRequestReceipt> = .idle

    private let requestAccountUseCase: RequestAccountUseCase

    init(requestAccountUseCase: RequestAccountUseCase) {
        self.requestAccountUseCase = requestAccountUseCase
    }

    var departments: [Department] {
        Department.selectable
    }

    var isSubmitting: Bool {
        submitState.isLoading
    }

    var canSubmit: Bool {
        form.isSubmittable && !isSubmitting
    }

    var errorMessage: String? {
        submitState.error?.userMessage
    }

    /// 이메일을 입력했는데 형식이 틀렸을 때만 안내
    var showsEmailHint: Bool {
        !form.email.isEmpty && !form.isEmailValid
    }

    /// 비밀번호를 입력하기 시작했을 때만 규칙 결과를 보여줍니다.
    var passwordRuleState: PasswordRuleState {
        if form.password.isEmpty { return .idle }
        return form.isPasswordValid ? .valid : .invalid
    }

    func select(_ department: Department) {
        form.department = department
        isDepartmentPickerPresented = false
        clearError()
    }

    @discardableResult
    func submit() async -> AccountRequestReceipt? {
        guard canSubmit else { return nil }
        submitState = .loading
        do {
            let receipt = try await requestAccountUseCase.execute(form)
            submitState = .loaded(receipt)
            return receipt
        } catch {
            AppLog.record(error, context: "requestAccount", logger: AppLog.auth)
            submitState = .failed(error)
            return nil
        }
    }

    func clearError() {
        if submitState.error != nil {
            submitState = .idle
        }
    }
}
