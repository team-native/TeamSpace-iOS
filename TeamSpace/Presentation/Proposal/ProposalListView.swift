import SwiftUI

/// 12-1b 운영 제안 목록 (Figma 수정본) — 정렬 · 진행 단계 · 부서 · 상태
struct ProposalListView: View {
    @State private var viewModel: ProposalListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProposalListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ProposalFilterBar(viewModel: viewModel)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "운영 제안", onBack: { dismiss() }) {
                Button("글쓰기") { onNavigate(.proposalCompose) }
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "운영 제안을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.proposals.isEmpty {
                InfoBanner(message: "조건에 맞는 제안이 없어요. 필터를 바꿔 보세요.", style: .muted)
            }
            ForEach(viewModel.proposals) { proposal in
                ProposalCard(proposal: proposal) { onNavigate(.proposalDetail(id: proposal.id)) }
            }
        }
    }
}

/// 12-1b 정렬 · 단계 칩 + 부서 · 상태 메뉴
private struct ProposalFilterBar: View {
    @Bindable var viewModel: ProposalListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(ProposalSort.allCases, id: \.self) { sort in
                        FilterChip(title: sort.title, isSelected: viewModel.sort == sort) { viewModel.sort = sort }
                    }
                    Rectangle().fill(Color.tsLine).frame(width: 1, height: 18)
                    ForEach(ProposalPhase.allCases, id: \.self) { phase in
                        FilterChip(title: phase.title, isSelected: viewModel.phase == phase) { viewModel.togglePhase(phase) }
                    }
                }
                .padding(1)
            }
            HStack(spacing: Spacing.xs) {
                Menu {
                    Button("부서 전체") { viewModel.department = nil }
                    ForEach(viewModel.departments, id: \.self) { name in
                        Button(name) { viewModel.department = name }
                    }
                } label: { ProposalMenuLabel(title: viewModel.departmentTitle, isActive: viewModel.department != nil) }
                Menu {
                    Button("상태 전체") { viewModel.status = nil }
                    ForEach(viewModel.statuses, id: \.self) { status in
                        Button(status.title) { viewModel.status = status }
                    }
                } label: { ProposalMenuLabel(title: viewModel.statusTitle, isActive: viewModel.status != nil) }
            }
        }
    }
}

/// "부서 전체 ⌄"
private struct ProposalMenuLabel: View {
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .tsFont(.captionBold)
            TSIcon.chevronDown.sized(.xs)
        }
        .foregroundStyle(isActive ? Color.tsPrimary : Color.tsInk2)
        .padding(.horizontal, Spacing.md)
        .frame(height: 32)
        .background(isActive ? Color.tsPrimarySoft : Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

/// 12-1b 제안 카드 — 부서 · 상태 · 제목 · 내용 · 작성자 · 날짜 · 댓글 · 추천
private struct ProposalCard: View {
    let proposal: ProposalSummary
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            WorkspaceCard {
                HStack(spacing: Spacing.xs) {
                    StatusBadge(title: proposal.department, tone: .neutral, size: .small)
                    StatusBadge(status: proposal.status, size: .small)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(proposal.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .multilineTextAlignment(.leading)
                    Text(proposal.excerpt)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                        .lineLimit(1)
                }
                HStack {
                    Text(proposal.authorDateText)
                    Spacer(minLength: Spacing.sm)
                    Text(proposal.countText)
                }
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ProposalListView(viewModel: DIContainer.preview().makeProposalListViewModel(), onNavigate: { _ in })
    }
}
