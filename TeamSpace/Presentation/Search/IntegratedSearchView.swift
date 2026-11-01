import SwiftUI

/// 13 통합 검색 — 권한 안의 문서 · 규정 · 프로젝트 · 팀원 · 공개 글 · 운영 제안을 한 번에 찾아요.
struct IntegratedSearchView: View {
    @State private var viewModel: IntegratedSearchViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: IntegratedSearchViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.title)
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                    Text("내가 볼 수 있는 정보에서 찾아요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
                SearchField(placeholder: "문서 · 프로젝트 · 팀원 · 게시글 검색", text: $viewModel.query, autoFocus: true)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "통합 검색", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: viewModel.query) {
            try? await Task.sleep(nanoseconds: IntegratedSearchViewModel.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            InfoBanner(
                message: viewModel.isQueryTooShort
                    ? "검색어는 2자 이상 입력해 주세요."
                    : "문서 · 규정, 프로젝트, 팀원, 공개 게시글 · 운영 제안을 한 번에 찾아요.",
                icon: .search,
                style: .muted
            )
        case .loading:
            LoadingSkeletonView(message: "검색하는 중이에요", count: 2)
        case .empty:
            NoResultsView(query: viewModel.query, onEditQuery: { viewModel.clearQuery() })
        case .forbidden:
            InfoBanner(message: "검색을 사용할 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "검색하지 못했어요") { Task { await viewModel.search() } }
        case .loaded:
            results
        }
    }

    @ViewBuilder
    private var results: some View {
        SearchFilterChips(viewModel: viewModel)
        if viewModel.isFilteredEmpty {
            NoResultsView(
                query: viewModel.query,
                onResetFilters: { viewModel.resetFilter() },
                onEditQuery: { viewModel.clearQuery() }
            )
        } else {
            Text(viewModel.summaryText)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            InfoBanner(
                message: "권한 안의 결과만 표시해요. 익명 문의와 익명 작성자의 신원 · 소속을 짐작할 수 있는 내용은 검색 결과에서 제외돼요. 내 익명 활동은 내 공간에서만 확인해요.",
                icon: .infoCircle,
                style: .hint
            )
            ForEach(viewModel.sections) { section in
                SearchSectionView(section: section, onOpen: { onNavigate($0.route) })
            }
            Text(viewModel.baseDateText)
                .tsFont(.micro)
                .fontWeight(.regular)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

#Preview {
    NavigationStack {
        IntegratedSearchView(viewModel: DIContainer.preview().makeIntegratedSearchViewModel(), onNavigate: { _ in })
    }
}
