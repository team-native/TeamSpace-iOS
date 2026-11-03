import SwiftUI

/// 재정 열람 권한 관리 [Admin] — 검색 · 사람마다 열람 권한 토글
struct FinancePermissionView: View {
    @State private var viewModel: FinancePermissionViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: FinancePermissionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "재정 권한", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .tsToast($viewModel.toastMessage)
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView()
        case .empty, .forbidden:
            InfoBanner(message: "관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            InfoBanner(message: "권한을 주면 FA 역할이 더해져 수주 상세 · 프로젝트별 금액 · 거래 내역을 볼 수 있어요.", style: .muted)
            SearchField(placeholder: "이름, 이메일 검색", text: $viewModel.query)
            Text(viewModel.summaryText)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk3)
            if viewModel.members.isEmpty {
                InfoBanner(message: "검색 결과가 없어요.", style: .muted)
            } else {
                WorkspaceCard {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        if index > 0 { TSDivider() }
                        FinancePermissionRow(
                            member: member,
                            isProcessing: viewModel.processingId == member.id,
                            onChange: { canView in Task { await viewModel.setCanViewFinance(member, to: canView) } }
                        )
                    }
                }
            }
        }
    }
}

/// 한 사람 — 이름 · 역할 · 이메일 · 토글 (Leader · Admin 은 잠김)
private struct FinancePermissionRow: View {
    let member: FinancePermissionMember
    let isProcessing: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { member.canViewFinance }, set: onChange)) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("\(member.name) · \(member.roleText)")
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Text(member.lockNote ?? member.email)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
        }
        .tint(Color.tsPrimary)
        .disabled(member.isLockedByRole || isProcessing)
        .padding(.vertical, Spacing.xs)
        .accessibilityHint(member.lockNote ?? "")
    }
}

#Preview {
    NavigationStack {
        FinancePermissionView(
            viewModel: DIContainer.preview().makeFinancePermissionViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin]))
        )
    }
}
