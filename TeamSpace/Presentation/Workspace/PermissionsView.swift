import SwiftUI

/// 07-15 내 권한 · 접근 범위
struct PermissionsView: View {
    @State private var viewModel: PermissionsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: PermissionsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    WorkspacePageTitle(eyebrow: "역할과 권한 안내", title: "내가 할 수 있는 일을 확인해요")
                    StatusBadge(title: "권한 정책 예시 · 운영 확정 필요", tone: .violet, size: .small)
                }
                WorkspaceNote(message: "역할별 범위는 화면 설계를 위한 예시이며 사용자에게 확정된 운영정책이 아니에요. 실제 권한은 운영자 검토 후 부여돼요.")
                CurrentRoleCard(viewModel: viewModel)
                AllowedFeaturesCard(features: viewModel.user.allowedFeatures)
                RoleScopeCard()
                RestrictedFinanceCard()
                PermissionRequestCard { onNavigate(.comingSoon(title: "문의 · 건의")) }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 권한과 접근 범위", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        PermissionsView(
            viewModel: DIContainer.preview().makePermissionsViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.member])),
            onNavigate: { _ in }
        )
    }
}
