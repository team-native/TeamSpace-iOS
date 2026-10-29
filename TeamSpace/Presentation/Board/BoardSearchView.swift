import SwiftUI

/// 10-12 게시글 검색 — 최근 검색어 · 공지 + 게시글 결과
struct BoardSearchView: View {
    @State private var viewModel: BoardSearchViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BoardSearchViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if viewModel.showsRecent {
                    BoardRecentKeywords(
                        keywords: viewModel.recentKeywords,
                        onSelect: { viewModel.selectRecent($0) },
                        onRemove: { viewModel.removeRecent($0) },
                        onClear: { viewModel.clearRecent() }
                    )
                }
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) { searchBar }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: viewModel.query) {
            try? await Task.sleep(nanoseconds: BoardSearchViewModel.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            SearchField(placeholder: "게시글 · 댓글 검색", text: $viewModel.query, autoFocus: true)
                .onSubmit { viewModel.submit() }
            Button("취소") { dismiss() }
                .tsFont(.calloutBold)
                .foregroundStyle(Color.tsPrimary)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(Color.tsBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty:
            InfoBanner(message: viewModel.emptyMessage, icon: .search, style: .muted)
        case .forbidden:
            InfoBanner(message: "게시판을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.search() } }
        case .loaded(let result):
            BoardSearchResultList(
                title: viewModel.resultTitle,
                result: result,
                onOpenNotice: { open(.comingSoon(title: $0.title)) },
                onOpenPost: { open(.comingSoon(title: $0.title)) }
            )
        }
    }

    private func open(_ route: AppRoute) {
        viewModel.didOpenResult()
        onNavigate(route)
    }
}

/// 10-12 최근 검색어 — 칩마다 × , 오른쪽 "전체 삭제"
private struct BoardRecentKeywords: View {
    let keywords: [String]
    let onSelect: (String) -> Void
    let onRemove: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("최근 검색어")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Spacer()
                Button("전체 삭제", action: onClear)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            FlowLayout(spacing: Spacing.xs) {
                ForEach(keywords, id: \.self) { keyword in
                    HStack(spacing: Spacing.xxs) {
                        Button(keyword) { onSelect(keyword) }
                            .tsFont(.captionMedium)
                            .foregroundStyle(Color.tsInk2)
                        Button { onRemove(keyword) } label: {
                            TSIcon.close.sized(.xxs, weight: .bold)
                                .foregroundStyle(Color.tsInk3)
                                .frame(width: 20, height: 20)
                        }
                        .accessibilityLabel("\(keyword) 지우기")
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, Spacing.md)
                    .padding(.trailing, Spacing.xs)
                    .frame(height: 30)
                    .background(Color.tsSurface, in: Capsule())
                    .overlay(Capsule().stroke(Color.tsLine, lineWidth: 1))
                }
            }
        }
    }
}

/// 10-12 결과 — 공지는 분류 · 날짜 · 요약, 게시글은 "팀 게시판 · 작성자 · 날짜 · 추천 · 댓글"
private struct BoardSearchResultList: View {
    let title: String
    let result: BoardSearchResult
    var now = Date()
    let onOpenNotice: (NoticeSummary) -> Void
    let onOpenPost: (PostSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk2)
            WorkspaceCard {
                ForEach(Array(result.notices.enumerated()), id: \.element.id) { index, notice in
                    if index > 0 { TSDivider() }
                    Button { onOpenNotice(notice) } label: { noticeRow(notice) }
                        .buttonStyle(.plain)
                }
                ForEach(Array(result.posts.enumerated()), id: \.element.id) { index, post in
                    if index > 0 || !result.notices.isEmpty { TSDivider() }
                    Button { onOpenPost(post) } label: {
                        WorkspaceItemText(title: post.title, meta: post.searchMetaText(now: now))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func noticeRow(_ notice: NoticeSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: "공지", tone: .primary, size: .small)
                Text("\(notice.category.title) · \(TSFormat.dayLabel(notice.updatedAt, now: now))")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            WorkspaceItemText(title: notice.title, meta: notice.summary ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        BoardSearchView(viewModel: DIContainer.preview().makeBoardSearchViewModel(), onNavigate: { _ in })
    }
}
