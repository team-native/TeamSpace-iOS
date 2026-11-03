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
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            AccessDeniedView(
                onBack: { dismiss() }
            )
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
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
            if viewModel.canManage {
                ProposalManageCard(viewModel: viewModel)
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
