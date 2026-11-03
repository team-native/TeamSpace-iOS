import Foundation
import Observation

/// 재정 열람 권한 관리 [Admin] — GET · PATCH /admin/finance/permissions
@Observable
@MainActor
final class FinancePermissionViewModel {
    private(set) var state: ViewState<[FinancePermissionMember]> = .idle
    var query = ""
    private(set) var processingId: Int?
    var toastMessage: String?
    var errorMessage: String?

    private let user: AuthUser
    private let fetchFinancePermissionsUseCase: FetchFinancePermissionsUseCase
    private let changeFinancePermissionUseCase: ChangeFinancePermissionUseCase

    init(
        user: AuthUser,
        fetchFinancePermissionsUseCase: FetchFinancePermissionsUseCase,
        changeFinancePermissionUseCase: ChangeFinancePermissionUseCase
    ) {
        self.user = user
        self.fetchFinancePermissionsUseCase = fetchFinancePermissionsUseCase
        self.changeFinancePermissionUseCase = changeFinancePermissionUseCase
    }

    private var all: [FinancePermissionMember] { state.value ?? [] }

    /// 이름 · 이메일 검색
    var members: [FinancePermissionMember] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(keyword) || $0.email.localizedCaseInsensitiveContains(keyword) }
    }

    /// "열람 가능 3명 · 전체 7명"
    var summaryText: String {
        "열람 가능 \(all.filter(\.canViewFinance).count)명 · 전체 \(all.count)명"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchFinancePermissionsUseCase.execute(user: user))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.permissions.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func setCanViewFinance(_ member: FinancePermissionMember, to canView: Bool) async {
        guard processingId == nil, member.canViewFinance != canView else { return }
        processingId = member.id
        defer { processingId = nil }
        do {
            let updated = try await changeFinancePermissionUseCase.execute(member, canViewFinance: canView, user: user)
            var items = all
            if let index = items.firstIndex(where: { $0.id == updated.id }) { items[index] = updated }
            state = .loaded(items)
            toastMessage = updated.canViewFinance ? "\(updated.name)님에게 재정 열람 권한을 줬어요" : "\(updated.name)님의 재정 열람 권한을 회수했어요"
        } catch {
            AppLog.record(error, context: "finance.permissions.change")
            errorMessage = error.userMessage
        }
    }
}

extension FinancePermissionMember {
    /// "FA · PM" — 구성원만이면 "구성원"
    var roleText: String {
        let titles = roles.filter { $0 != .member && $0 != .unknown }.map(\.rawValue)
        return titles.isEmpty ? "구성원" : titles.joined(separator: " · ")
    }

    var lockNote: String? {
        isLockedByRole ? "Leader · Admin 역할이라 늘 볼 수 있어요" : nil
    }
}
