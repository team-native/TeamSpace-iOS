import SwiftUI

/// 10-1 팀 게시판 (Figma 수정본) — 검색 · 기간 · 분류 · 고정 공지 · 게시글 · 인기글 · 운영 제안 · 내 기록
struct BoardView: View {
    @State private var viewModel: BoardViewModel
    @State private var isShowingPeriodSheet = false
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BoardViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                BoardSearchEntry { onNavigate(.boardSearch) }
                BoardPeriodBar(
                    selection: viewModel.period,
                    onSelect: { viewModel.selectPeriod($0) },
                    onCustom: { isShowingPeriodSheet = true }
                )
                WorkspacePageTitle(eyebrow: "• TEAMSPACE · 팀 게시판", title: "함께 나누는 생각이\n팀을 더 나아지게 해요.")
                BoardInquiryBanner { onNavigate(.comingSoon(title: "문의 · 건의")) }
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, 96)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "팀 게시판", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .overlay(alignment: .bottomTrailing) {
            BoardWriteButton { onNavigate(.postCompose) }
                .padding(.trailing, Spacing.screen)
                .padding(.bottom, Spacing.lg)
        }
        .sheet(isPresented: $isShowingPeriodSheet) {
            BoardPeriodSheet(period: viewModel.period) { viewModel.selectPeriod($0) }
                .presentationDetents([.height(400)])
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
            InfoBanner(message: "게시판을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let board):
            BoardListHeader(
                inquiryCount: viewModel.inquiryCount,
                sort: viewModel.sort,
                onOpenInquiries: { onNavigate(.comingSoon(title: "내 문의")) },
                onSort: { viewModel.sort = $0 }
            )
            BoardFilterBar(selection: viewModel.filter) { viewModel.filter = $0 }
            posts
            if !viewModel.popularPosts.isEmpty {
                PopularPostsCard(
                    posts: viewModel.popularPosts,
                    rangeText: viewModel.popularRangeText,
                    onOpen: { onNavigate(.postDetail(id: $0.id)) },
                    onShowMore: { viewModel.showPopular() }
                )
            }
            BoardProposalCard(
                onWrite: { onNavigate(.comingSoon(title: "운영 제안 쓰기")) },
                onBrowse: { onNavigate(.comingSoon(title: "운영 제안")) }
            )
            WorkspaceRecordsCard(records: board.myRecord, onOpen: onNavigate)
        }
    }

    @ViewBuilder
    private var posts: some View {
        if !viewModel.pinnedNotices.isEmpty {
            PinnedNoticeCard(notices: viewModel.pinnedNotices) { onNavigate(.comingSoon(title: $0.title)) }
        }
        if let message = viewModel.emptyMessage {
            InfoBanner(message: message, icon: .search, style: .muted)
        }
        ForEach(viewModel.posts) { post in
            BoardPostCard(post: post) { onNavigate(.postDetail(id: post.id)) }
        }
    }
}

#Preview {
    NavigationStack {
        BoardView(viewModel: DIContainer.preview().makeBoardViewModel(), onNavigate: { _ in })
    }
}
