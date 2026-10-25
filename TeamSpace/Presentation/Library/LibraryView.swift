import SwiftUI

/// 06-1 문서함 (문서함 탭 첫 화면)
struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    private let onNavigate: (AppRoute) -> Void

    init(viewModel: LibraryViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LibraryHeader()
                    .padding(.top, Spacing.sm)
                Button { onNavigate(.librarySearch) } label: {
                    LibrarySearchBar()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("문서 검색")
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.tabBarInset)
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "문서함을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            LibraryCategoryGrid(viewModel: viewModel)
            if let revision = viewModel.latestRevision {
                Button { onNavigate(.comingSoon(title: revision.title)) } label: {
                    RevisionBanner(revision: revision)
                }
                .buttonStyle(.plain)
            }
            LibraryDocumentSection(
                title: viewModel.filter.title,
                countText: viewModel.countText,
                documents: viewModel.filteredDocuments,
                onOpen: open
            )
        }
    }

    private func open(_ document: LibraryDocument) {
        onNavigate(document.route)
    }
}

#Preview {
    NavigationStack {
        LibraryView(viewModel: DIContainer.preview().makeLibraryViewModel(), onNavigate: { _ in })
    }
}
