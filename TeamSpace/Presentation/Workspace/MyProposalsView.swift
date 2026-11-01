import SwiftUI

/// 07-11 내가 작성한 운영 제안
struct MyProposalsView: View {
    @State private var viewModel: MyProposalsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyProposalsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WorkspacePageTitle(eyebrow: "내가 작성한 운영 제안", title: "내 제안이 바꾸는 팀의 일상")
                    Text(viewModel.subtitle)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
                HStack(spacing: Spacing.xs) {
                    ForEach(ProposalFilter.allCases, id: \.self) { filter in
                        WorkspaceCountChip(
                            title: "\(filter.title) \(viewModel.count(of: filter))",
                            isSelected: viewModel.filter == filter
                        ) { viewModel.filter = filter }
                    }
                }
                WorkspaceNote(message: "팀 게시판의 일반 제안 글과는 구분돼요. 운영 제안의 검토 상태와 추천수를 함께 확인해요.")
                content
                Button("운영 제안 전체 보기") { onNavigate(.comingSoon(title: "운영 제안")) }
                    .buttonStyle(.tsSecondary)
                Text(viewModel.baseDateText)
                    .tsFont(.micro)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 운영 제안", onBack: { dismiss() })
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
            Text("최근 작성순")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            if viewModel.proposals.isEmpty {
                InfoBanner(message: "이 상태의 제안이 없어요.", icon: .infoCircle, style: .muted)
            }
            ForEach(viewModel.proposals) { proposal in
                MyProposalCard(proposal: proposal) { onNavigate(.comingSoon(title: proposal.title)) }
            }
        }
    }
}

/// 07-11 제안 카드 — 날짜 · 분류 · 상태 · 제목 · 내용 · 추천 · 댓글
private struct MyProposalCard: View {
    let proposal: MyProposal
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: proposal.category, tone: .neutral, size: .small)
                Text(proposal.headerText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: proposal.status, size: .small)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(proposal.title)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(proposal.body)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .lineLimit(2)
            }
            HStack {
                Text("추천 \(proposal.recommendCount)")
                    .tsFont(.captionBold)
                    .foregroundStyle(Color.tsPrimary)
                Spacer()
                Text("댓글 \(proposal.commentCount)")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
            }
            WorkspaceLinkRow(title: proposal.linkTitle, action: onOpen)
        }
    }
}

#Preview {
    NavigationStack {
        MyProposalsView(viewModel: DIContainer.preview().makeMyProposalsViewModel(userName: "옥물결"), onNavigate: { _ in })
    }
}
