import Foundation
import Observation

/// 07-15 내 권한 · 접근 범위 — 역할은 로그인 정보, 소속은 프로필에서 가져와요.
@Observable
@MainActor
final class PermissionsViewModel {
    let user: AuthUser
    private(set) var affiliation: String?

    private let fetchProfileUseCase: FetchProfileUseCase

    init(user: AuthUser, fetchProfileUseCase: FetchProfileUseCase) {
        self.user = user
        self.fetchProfileUseCase = fetchProfileUseCase
    }

    /// "구성원 · 옥물결"
    var roleBadgeText: String {
        "\(user.roleTitle) · \(user.name)"
    }

    func load() async {
        do {
            affiliation = try await fetchProfileUseCase.execute().affiliation
        } catch {
            // 소속이 없어도 권한 안내는 보여줄 수 있어요.
            AppLog.record(error, context: "workspace.permissions.affiliation")
        }
    }
}
