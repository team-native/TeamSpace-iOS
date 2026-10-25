import SwiftUI

/// 04-3 수금 내역 전체
struct ContractLedgerView: View {
    @State private var viewModel: ContractLedgerViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractLedgerViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FilterChipBar(
                    items: CollectionFilter.allCases,
                    selection: viewModel.filter,
                    title: { $0.title },
                    onSelect: { viewModel.filter = $0 }
                )
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "수금 내역", onBack: { dismiss() }) {
                Menu {
                    Picker("정렬", selection: $viewModel.sort) {
                        ForEach(CollectionSort.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                } label: {
                    TSIcon.filter.sized(.base)
                        .foregroundStyle(Color.tsInk)
                        .frame(width: 36, height: 36)
                        .background(Color.tsSurface, in: Circle())
                }
                .accessibilityLabel("정렬")
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "수금 내역을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let ledger):
            LedgerTotalCard(title: viewModel.totalTitle, amount: ledger.totalAmount)
            if viewModel.groups.isEmpty {
                InfoBanner(message: "이 조건에 맞는 수금 내역이 없어요.", icon: .infoCircle, style: .muted)
            }
            ForEach(viewModel.groups) { group in
                LedgerMonthGroup(title: viewModel.groupTitle(group), contracts: group.contracts) { contract in
                    onNavigate(.financeContractDetail(id: contract.id))
                }
            }
        }
    }
}

private struct LedgerTotalCard: View {
    let title: String
    let amount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxxs) {
                Text(TSFormat.number(amount))
                    .tsFont(.title3)
                Text("원")
                    .tsFont(.subheadline)
            }
            .foregroundStyle(Color.tsInk)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LedgerMonthGroup: View {
    let title: String
    let contracts: [FinanceContract]
    let onSelect: (FinanceContract) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
            Text(title)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk3)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(contracts.enumerated()), id: \.element.id) { index, contract in
                    if index > 0 { TSDivider() }
                    Button { onSelect(contract) } label: { FinanceContractRow(contract: contract) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg + Spacing.xxxs)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        ContractLedgerView(viewModel: DIContainer.preview().makeContractLedgerViewModel(year: 2026), onNavigate: { _ in })
    }
}
