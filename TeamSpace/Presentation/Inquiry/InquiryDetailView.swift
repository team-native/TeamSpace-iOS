import SwiftUI

/// 11-4 문의 상세 · 작성자 / 11-7 반려 — 보낸 내용 · 처리 이력 · 답변(반려 사유) · 관련 자료
struct InquiryDetailView: View {
    @State private var viewModel: InquiryDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: InquiryDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
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
            TSNavigationBar(title: "내 문의 상세", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let title = viewModel.followUpTitle, let inquiry = viewModel.detail?.inquiry {
                Button(title) { onNavigate(.inquiryCompose(.followUp(inquiry))) }
                    .buttonStyle(.tsSecondary)
                    .padding(.horizontal, Spacing.screen)
                    .padding(.vertical, Spacing.md)
                    .background(Color.tsBackground)
            }
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
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            InfoBanner(message: "작성자 본인만 볼 수 있는 문의예요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
        case .loaded(let detail):
            InquiryDetailHeader(inquiry: detail.inquiry)
            InquiryBodyCard(text: detail.inquiry.body)
            InquiryHistoryCard(history: detail.history)
            if let reply = detail.inquiry.reply {
                InquiryReplyCard(reply: reply, isRejection: detail.inquiry.status == .rejected)
            }
            if let reference = detail.reference {
                InquiryReferenceCard(reference: reference) { onNavigate(reference.route) }
            }
            InfoBanner(
                message: "익명 문의의 작성자 정보는 일반 사용자에게 비공개예요. 담당자의 열람 범위는 별도 운영정책에 따라요. "
                    + "문의 본문과 공식 답변은 팀 게시판에 자동 공개되지 않아요.",
                icon: .lock,
                style: .muted
            )
        }
    }
}

#Preview {
    NavigationStack {
        InquiryDetailView(viewModel: DIContainer.preview().makeInquiryDetailViewModel(inquiryId: 42), onNavigate: { _ in })
    }
}
