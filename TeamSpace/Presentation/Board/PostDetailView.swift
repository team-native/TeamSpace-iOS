import SwiftUI

/// 10-3 게시글 상세 — 본문 · 공감 · 링크 복사 · 댓글 (… 은 10-8 더보기)
struct PostDetailView: View {
    @State private var viewModel: PostDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
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
            TSNavigationBar(title: "팀 게시판", onBack: { dismiss() }) {
                if viewModel.detail != nil {
                    CircleIconButton(icon: .ellipsis, accessibilityLabel: "더보기", background: .tsSurface, hasBorder: true) {
                        viewModel.isMorePresented = true
                    }
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { commentBar }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .modifier(PostDetailDialogs(viewModel: viewModel, onCopyLink: copyLink))
        .tsToast($viewModel.toastMessage)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            if isDeleted { dismiss() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 게시글을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            PostDetailHeader(detail: detail)
            PostReactionBar(
                detail: detail,
                isLiking: viewModel.isLiking,
                onLike: { Task { await viewModel.toggleLike() } },
                onCopyLink: copyLink
            )
            PostCommentSection(detail: detail)
        }
    }

    @ViewBuilder
    private var commentBar: some View {
        if let detail = viewModel.detail {
            Button(detail.commentButtonTitle) { onNavigate(.commentCompose(postId: detail.post.id)) }
                .buttonStyle(.tsPrimaryLarge)
                .padding(.horizontal, Spacing.screen)
                .padding(.vertical, Spacing.md)
                .background(Color.tsBackground)
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = viewModel.link
        viewModel.didCopyLink()
    }
}

/// 10-8 더보기 · 10-10 신고 · 오류 알림
private struct PostDetailDialogs: ViewModifier {
    @Bindable var viewModel: PostDetailViewModel
    let onCopyLink: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog("게시글 더보기", isPresented: $viewModel.isMorePresented, titleVisibility: .hidden) {
                Button("링크 복사", action: onCopyLink)
                if viewModel.canReport {
                    Button("신고하기") { Task { await viewModel.requestReport() } }
                }
                if viewModel.canDelete {
                    Button("삭제하기", role: .destructive) { Task { await viewModel.delete() } }
                }
                Button("취소", role: .cancel) {}
            }
            .confirmationDialog("신고 사유를 선택해 주세요", isPresented: $viewModel.isReportPresented, titleVisibility: .visible) {
                ForEach(PostReportReason.allCases, id: \.self) { reason in
                    Button(reason.title) { Task { await viewModel.report(reason) } }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("신고 내용은 NativeOps만 확인해요.")
            }
            .alert(viewModel.errorMessage ?? "", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            }
    }
}

#Preview {
    NavigationStack {
        PostDetailView(viewModel: DIContainer.preview().makePostDetailViewModel(postId: 41), onNavigate: { _ in })
    }
}
