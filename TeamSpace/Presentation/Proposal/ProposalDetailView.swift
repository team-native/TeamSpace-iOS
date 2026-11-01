import SwiftUI

/// 12-2b 운영 제안 상세 (Figma 수정본) — 본문 · 추천 · 진행 상태 · 답변 · 댓글
struct ProposalDetailView: View {
    @State private var viewModel: ProposalDetailViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProposalDetailViewModel) {
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
            TSNavigationBar(title: "제안 상세", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.detail != nil {
                ProposalCommentBar(viewModel: viewModel)
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 제안을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            ProposalDetailHeader(detail: detail)
            ProposalRecommendBar(
                detail: detail,
                note: viewModel.recommendNote,
                isLoading: viewModel.isRecommending,
                onRecommend: { Task { await viewModel.toggleRecommend() } }
            )
            ProposalStepsCard(detail: detail)
            if let answer = detail.answer {
                ProposalAnswerCard(answer: answer)
            }
            ProposalCommentsCard(comments: detail.comments)
        }
    }
}

#Preview {
    NavigationStack {
        ProposalDetailView(viewModel: DIContainer.preview().makeProposalDetailViewModel(proposalId: 16))
    }
}
