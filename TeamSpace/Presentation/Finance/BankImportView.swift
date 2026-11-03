import SwiftUI

/// 은행 거래 확인 · 반영 [FA · Admin] — 확인할 거래 · 반영 대기 · 끝난 거래
struct BankImportView: View {
    @State private var viewModel: BankImportViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BankImportViewModel) {
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
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "은행 거래", onBack: { dismiss() })
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
            InfoBanner(message: "FA · 관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            InfoBanner(message: "은행에서 불러온 거래를 확인하면 반영 대기로 옮겨져요. 반영하면 입금은 수금, 출금은 지출로 재정에 들어가요.", style: .muted)
            TSSegmentedControl(
                items: BankImportViewModel.Filter.allCases,
                selection: viewModel.filter,
                title: { "\($0.rawValue) \(viewModel.count($0))" },
                onSelect: { viewModel.filter = $0 }
            )
            if viewModel.filter == .confirmed, viewModel.canCommit {
                WorkspaceCard {
                    Text(viewModel.confirmedTotalText)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk2)
                    Button(viewModel.commitTitle) { Task { await viewModel.commit() } }
                        .buttonStyle(.tsPrimary)
                        .disabled(!viewModel.canCommit)
                }
            }
            if viewModel.items.isEmpty {
                InfoBanner(message: "\(viewModel.filter.rawValue)가 없어요.", style: .muted)
            } else {
                ForEach(viewModel.items) { item in
                    BankImportCard(
                        item: item,
                        isProcessing: viewModel.processingId == item.id,
                        onReview: { action in Task { await viewModel.review(item, action) } }
                    )
                }
            }
        }
    }
}

/// 거래 한 줄 — 상대 · 금액 · 날짜 · 연결 계약 · 확인/제외
private struct BankImportCard: View {
    let item: BankImport
    let isProcessing: Bool
    let onReview: (ReviewBankImportUseCase.Action) -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(item.direction.rawValue)
                    .tsFont(.caption2Bold)
                    .foregroundStyle(item.direction == .inbound ? Color.tsPositive : Color.tsNegative)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(item.direction == .inbound ? Color.tsPositiveSoft : Color.tsNegativeSoft, in: Capsule())
                Spacer(minLength: Spacing.sm)
                Text(item.status.rawValue)
                    .tsFont(.caption2)
                    .foregroundStyle(item.status.isOpen ? Color.tsPrimary : Color.tsInk3)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(item.counterparty.isEmpty ? "상대 없음" : item.counterparty)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Spacer(minLength: Spacing.sm)
                Text(item.amountText)
                    .tsFont(.calloutBold)
                    .foregroundStyle(item.direction == .inbound ? Color.tsPositive : Color.tsInk)
            }
            Text("\(TSFormat.dateTime(item.date)) · \(item.matchText)")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
            if let committedAt = item.committedAt {
                Text("\(TSFormat.dateTime(committedAt)) \(item.committedBy ?? "") 반영")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            if item.status.isOpen {
                HStack(spacing: Spacing.sm) {
                    Button("제외") { onReview(.exclude) }
                        .buttonStyle(.ts(.secondary, size: .small))
                    Button("확인") { onReview(.confirm) }
                        .buttonStyle(.ts(.primary, size: .small))
                        .disabled(!item.canConfirm)
                }
                .disabled(isProcessing)
            } else if item.status == .confirmed {
                Button("확인 취소") { onReview(.unconfirm) }
                    .buttonStyle(.ts(.secondary, size: .small))
                    .disabled(isProcessing)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BankImportView(viewModel: DIContainer.preview().makeBankImportViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin])))
    }
}
