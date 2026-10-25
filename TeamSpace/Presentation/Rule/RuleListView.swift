import SwiftUI

/// 09-1 규칙 · 제도 전용 목록
struct RuleListView: View {
    @State private var viewModel: RuleListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: RuleListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WorkspacePageTitle(eyebrow: "달라진 규칙, 놓치지 않게 확인해요", title: "우리 팀의 기준을 읽어요")
                    Text("PDF를 내려받지 않아도 조항별로 바로 읽고, 달라진 내용을 비교할 수 있어요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
                SearchField(placeholder: "규칙 제목, 담당 부서 검색", text: $viewModel.query)
                RuleFilterBar(viewModel: viewModel)
                content
                WorkspaceNote(message: "실제 적용 여부와 세부 기준은 담당 부서의 최종 안내로 확인해 주세요.")
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "규칙·제도", onBack: { dismiss() })
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "규칙을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if let urgent = viewModel.urgentRule {
                UrgentRuleCard(rule: urgent) { onNavigate(.ruleDetail(id: urgent.id)) }
            }
            if viewModel.rules.isEmpty {
                InfoBanner(message: "조건에 맞는 규칙이 없어요. 검색어나 필터를 바꿔 보세요.", icon: .search, style: .muted)
            }
            ForEach(viewModel.rules) { rule in
                RuleCard(rule: rule, linkTitle: viewModel.linkTitle(for: rule)) { onNavigate(.ruleDetail(id: rule.id)) }
            }
        }
    }
}

/// 09-1 분류 칩 · 상태 칩
private struct RuleFilterBar: View {
    @Bindable var viewModel: RuleListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            FlowLayout(spacing: Spacing.xs) {
                FilterChip(title: "전체", isSelected: viewModel.category == nil) { viewModel.category = nil }
                ForEach(RuleCategory.selectable, id: \.self) { category in
                    FilterChip(title: category.title, isSelected: viewModel.category == category) { viewModel.category = category }
                }
            }
            FlowLayout(spacing: Spacing.xs) {
                ForEach(RuleStatusFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.title, isSelected: viewModel.statusFilter == filter) { viewModel.statusFilter = filter }
                }
            }
        }
    }
}

/// 09-1 시행 전 꼭 읽어주세요
private struct UrgentRuleCard: View {
    let rule: RuleSummary
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard(background: .tsPrimarySoft) {
            WorkspaceCardTitle(title: "시행 전 꼭 읽어주세요")
            StatusBadge(title: "중요 개정 · 읽음 미확인", tone: .primary, size: .small)
            WorkspaceItemText(title: "\(rule.title) \(rule.version)", meta: rule.urgentText)
            Button("본문 읽고 읽음 확인", action: onOpen)
                .buttonStyle(.tsPrimary)
        }
    }
}

/// 09-1 규칙 카드
private struct RuleCard: View {
    let rule: RuleSummary
    let linkTitle: String
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(rule.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: rule.status, size: .small)
            }
            WorkspaceItemText(title: rule.title, meta: rule.datesText)
            WorkspaceLinkRow(title: linkTitle, action: onOpen)
        }
    }
}

#Preview {
    NavigationStack {
        RuleListView(viewModel: DIContainer.preview().makeRuleListViewModel(), onNavigate: { _ in })
    }
}
