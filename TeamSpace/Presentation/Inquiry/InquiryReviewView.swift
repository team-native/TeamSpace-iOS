import SwiftUI

/// 11-6 문의 검토 · 공식 답변 작성 [담당자 운영 화면] — 원문 · 담당 배정 · 답변(반려) · 관련 규칙 · 전달 내용 · 처리 이력
struct InquiryReviewView: View {
    @State private var viewModel: InquiryReviewViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: InquiryReviewViewModel) {
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
            TSNavigationBar(title: "문의 검토 · 답변", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .tsToast($viewModel.toastMessage)
        .task { await viewModel.load() }
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
            InfoBanner(message: "문의 담당자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let item):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                StatusBadge(title: "\(item.inquiry.department.title) 담당자 권한", tone: .primary, icon: .lock, size: .small)
                Text(item.inquiry.title)
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.top, Spacing.sm)
            InquiryOriginalCard(item: item)
            InquiryAssignCard(viewModel: viewModel, item: item)
            if let reply = item.inquiry.reply {
                InquiryReplyCard(reply: reply, isRejection: item.inquiry.status == .rejected)
            } else if viewModel.isEditable {
                InquiryReplyEditor(viewModel: viewModel)
                InquiryDeliveryCard(statusChange: viewModel.statusChangeText)
                InquiryReplyActions(viewModel: viewModel)
            }
            InfoBanner(
                message: "익명 문의의 불필요한 신원 확인 없이 내용으로 처리해요. 일반 사용자에게 작성자는 비공개이며 담당자 열람 범위는 별도 운영정책에 따라요.",
                icon: .shield,
                style: .muted
            )
            InquiryHistoryCard(history: item.history)
        }
    }
}

#Preview {
    NavigationStack {
        InquiryReviewView(
            viewModel: DIContainer.preview().makeInquiryReviewViewModel(
                inquiryId: 51,
                user: AuthUser(id: 1, name: "양지우", roles: [.leader])
            )
        )
    }
}
