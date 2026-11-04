import SwiftUI

/// 재무 요약 설정 [FA · Admin] — 운영 · 적립 · 배당 풀의 지금 금액과 새 수금 배분 비율
struct FinanceSettingsView: View {
    @State private var viewModel: FinanceSettingsViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: FinanceSettingsViewModel) {
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
            TSNavigationBar(title: "재무 설정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
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
            InfoBanner(message: "FA · 관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            InfoBanner(message: "재무 요약의 풀 금액과, 새 수금이 들어올 때 나눌 비율이에요. 비율의 합은 100%여야 해요.", style: .muted)
            ForEach($viewModel.rows) { $row in
                WorkspaceCard {
                    Text(row.pool.label)
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsInk)
                    if let note = row.pool.note, !note.isEmpty {
                        Text(note)
                            .tsFont(.caption)
                            .foregroundStyle(Color.tsInk3)
                    }
                    HStack(spacing: Spacing.md) {
                        ComposeField(label: "지금 금액 (원)") {
                            TextField("0", text: $row.amountText)
                                .keyboardType(.numberPad)
                                .tsFont(.callout)
                        }
                        ComposeField(label: "비율 (%)") {
                            TextField("0", text: $row.ratioText)
                                .keyboardType(.numberPad)
                                .tsFont(.callout)
                        }
                        .frame(width: 96)
                    }
                }
            }
            HStack {
                Text(viewModel.ratioText)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(viewModel.ratioTotal == 100 ? Color.tsInk2 : Color.tsNegative)
                Spacer(minLength: Spacing.sm)
                Text(viewModel.amountTotalText)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            HStack(spacing: Spacing.sm) {
                Button("되돌리기") { viewModel.reset() }
                    .buttonStyle(.tsSecondary)
                    .disabled(!viewModel.hasChanges || viewModel.isSaving)
                Button("저장하기") { Task { await viewModel.save() } }
                    .buttonStyle(.tsPrimary)
                    .disabled(!viewModel.canSave)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FinanceSettingsView(viewModel: DIContainer.preview().makeFinanceSettingsViewModel(user: AuthUser(id: 5, name: "이시우", roles: [.fa])))
    }
}
