import PhotosUI
import SwiftUI

/// 10-2 게시글 작성 (Figma 수정본) — 작성자 표시 · 카테고리 · 제목 · 본문 · 사진 · 댓글 정책 → 10-9 게시 완료
struct PostComposeView: View {
    @State private var viewModel: PostComposeViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: PostComposeViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if viewModel.didRestoreDraft {
                    InfoBanner(message: "임시 저장한 글을 불러왔어요.", icon: .infoCircle)
                }
                PostAuthorModeSection(viewModel: viewModel)
                PostCategorySection(selection: viewModel.draft.category) { viewModel.draft.category = $0 }
                PostTextSection(viewModel: viewModel)
                PostImageSection(viewModel: viewModel)
                PostCommentPolicySection(selection: viewModel.draft.commentPolicy) { viewModel.draft.commentPolicy = $0 }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "글쓰기", onBack: { dismiss() }) {
                Button("임시 저장") {
                    viewModel.saveDraft()
                    dismiss()
                }
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsPrimary)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(viewModel.publishTitle) { Task { await viewModel.publish() } }
                .buttonStyle(.tsPrimaryLarge)
                .disabled(!viewModel.canPublish)
                .padding(.horizontal, Spacing.screen)
                .padding(.vertical, Spacing.md)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .modifier(PostComposeAlerts(viewModel: viewModel, onClose: { dismiss() }, onShowPost: showPost))
    }

    /// 10-9 "게시글 보기" — 작성 화면을 닫은 뒤 상세를 열어요.
    private func showPost(_ post: PostSummary) {
        dismiss()
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            onNavigate(.postDetail(id: post.id))
        }
    }
}

/// 10-9 게시 완료 · 오류 알림
private struct PostComposeAlerts: ViewModifier {
    @Bindable var viewModel: PostComposeViewModel
    let onClose: () -> Void
    let onShowPost: (PostSummary) -> Void

    func body(content: Content) -> some View {
        content
            .alert("게시글을 올렸어요", isPresented: Binding(
                get: { viewModel.publishedPost != nil },
                set: { if !$0 { viewModel.publishedPost = nil } }
            ), presenting: viewModel.publishedPost) { post in
                Button("확인", action: onClose)
                Button("게시글 보기") { onShowPost(post) }
            } message: { _ in
                Text(viewModel.completionMessage)
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
        PostComposeView(viewModel: DIContainer.preview().makePostComposeViewModel(), onNavigate: { _ in })
    }
}
