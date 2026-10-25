import SwiftUI

/// 04-1 재무 (재무 탭 첫 화면)
struct FinanceView: View {
    @State private var viewModel: FinanceViewModel
    private let onNavigate: (AppRoute) -> Void
    private let onSelectTab: (MainTab) -> Void

    init(
        viewModel: FinanceViewModel,
        onNavigate: @escaping (AppRoute) -> Void,
        onSelectTab: @escaping (MainTab) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
        self.onSelectTab = onSelectTab
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FinanceHeader(monthTitle: viewModel.monthTitle) {
                    viewModel.isPeriodPickerPresented = true
                }
                content
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabBarInset)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $viewModel.isPeriodPickerPresented) {
            PeriodPickerSheet(selection: viewModel.selectedMonth) { month in
                Task { await viewModel.selectMonth(month) }
            }
            .presentationDetents([.height(324)])
            .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 300)
        case .empty, .forbidden:
            InfoBanner(message: "재정 정보를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let overview):
            FinanceTrackerCard(overview: overview)
            FinanceSummarySection(overview: overview)
            FinanceMenuList(month: viewModel.selectedMonth, onSelect: { onNavigate($0) })
            Button {
                onNavigate(.financeAccess)
            } label: {
                InfoBanner(message: viewModel.permissionNotice, icon: .lock, style: .muted)
            }
            .buttonStyle(.plain)
            .accessibilityHint("공개 범위 자세히 보기")
            Button {
                onSelectTab(.approval)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("결재 안건 올리기")
                    TSIcon.arrowRight.sized(.base)
                }
            }
            .buttonStyle(.tsPrimaryLarge)
        }
    }
}

/// "재무" + 기간 선택 버튼
private struct FinanceHeader: View {
    let monthTitle: String
    let onPeriod: () -> Void

    var body: some View {
        HStack {
            Text("재무")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: onPeriod) {
                HStack(spacing: Spacing.xxs) {
                    Text(monthTitle)
                        .tsFont(.footnoteBold)
                    TSIcon.chevronDown.sized(.sm, weight: .bold)
                }
                .foregroundStyle(Color.tsInk2)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(height: 32)
                .background(Color.tsSurface2, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("기간 선택, \(monthTitle)")
        }
        .frame(height: 40)
    }
}

#Preview("라이트") {
    NavigationStack {
        FinanceView(
            viewModel: DIContainer.preview().makeFinanceViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.member])),
            onNavigate: { _ in },
            onSelectTab: { _ in }
        )
    }
}

#Preview("04-1a 다크 모드") {
    NavigationStack {
        FinanceView(
            viewModel: DIContainer.preview().makeFinanceViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.fa])),
            onNavigate: { _ in },
            onSelectTab: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
