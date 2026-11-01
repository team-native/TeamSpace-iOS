import SwiftUI

/// 06-2 문서 검색
struct LibrarySearchView: View {
    @State private var viewModel: LibrarySearchViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: LibrarySearchViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if !viewModel.recentKeywords.isEmpty {
                    RecentKeywordRow(keywords: viewModel.recentKeywords, onSelect: { viewModel.selectRecent($0) })
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
            try? await Task.sleep(nanoseconds: LibrarySearchViewModel.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.md) {
            SearchField(placeholder: "찾고 싶은 문서를 검색해 보세요", text: $viewModel.query, autoFocus: true)
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
            InfoBanner(message: "문서함을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.search() } }
        case .loaded:
            LibraryDocumentSection(
                title: viewModel.resultTitle,
                countText: nil,
                documents: viewModel.results,
                onOpen: open
            )
        }
    }

    private func open(_ document: LibraryDocument) {
        viewModel.didOpenResult()
        onNavigate(document.route)
    }
}

/// 06-2 최근 검색 칩 줄
private struct RecentKeywordRow: View {
    let keywords: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: "최근 검색", tone: .primaryFilled)
                ForEach(keywords, id: \.self) { keyword in
                    FilterChip(title: keyword, isSelected: false) { onSelect(keyword) }
                }
            }
            .padding(1)
        }
    }
}

#Preview {
    NavigationStack {
        LibrarySearchView(viewModel: DIContainer.preview().makeLibrarySearchViewModel(), onNavigate: { _ in })
    }
}
