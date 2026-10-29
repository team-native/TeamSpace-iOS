import SwiftUI

/// 07-10 내가 쓴 게시글 · 댓글
struct MyPostsView: View {
    @State private var viewModel: MyPostsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyPostsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                WorkspacePageTitle(eyebrow: "내가 쓴 글을 한눈에 볼 수 있어요", title: "내가 남긴 이야기")
                HStack(spacing: Spacing.xs) {
                    ForEach(MyPostsTab.allCases, id: \.self) { tab in
                        FilterChip(title: viewModel.title(for: tab), isSelected: viewModel.tab == tab) { viewModel.tab = tab }
                    }
                }
                WorkspaceNote(message: "이 화면은 나만 볼 수 있어요. 공개 게시판에서는 숨겨진 내 익명 활동도 여기서는 본인이 확인할 수 있어요.")
                content
                Text("글과 댓글의 실명·익명 여부는 각각 작성자가 선택해요. 익명 문의는 별도의 ‘내 문의’에서 확인해요.")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 게시글·댓글", onBack: { dismiss() })
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
            InfoBanner(message: "내 글을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            switch viewModel.tab {
            case .posts:
                ForEach(viewModel.posts) { post in
                    MyPostCard(post: post, authorName: viewModel.userName) {
                        onNavigate(.postDetail(id: post.id))
                    }
                }
                if let comment = viewModel.comments.first {
                    RecentCommentCard(comment: comment) { viewModel.tab = .comments }
                }
            case .comments:
                ForEach(viewModel.comments) { comment in
                    MyCommentCard(comment: comment) { onNavigate(.postDetail(id: comment.postId)) }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyPostsView(viewModel: DIContainer.preview().makeMyPostsViewModel(userName: "옥물결"), onNavigate: { _ in })
    }
}
