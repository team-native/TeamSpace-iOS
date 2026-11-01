import SwiftUI

/// 07-4 내가 제출한 문서
struct MyDocumentsView: View {
    @State private var viewModel: MyDocumentsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyDocumentsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                WorkspacePageTitle(eyebrow: "내 문서를 쉽고 빠르게 보거나 찾을 수 있어요", title: "제출부터 결과까지 한눈에")
                SearchField(placeholder: "문서 제목, 프로젝트 검색", text: $viewModel.query)
                MyDocumentFilters(viewModel: viewModel)
                content
                WorkspaceNote(message: "반려 문서의 재상신은 원래 문서와 이력이 연결돼요. 임시 저장 문서의 새 제출과는 구분해요.")
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내가 제출한 문서", onBack: { dismiss() })
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
            InfoBanner(message: "문서를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.documents.isEmpty {
                InfoBanner(message: "조건에 맞는 문서가 없어요. 검색어나 필터를 바꿔 보세요.", icon: .search, style: .muted)
            }
            ForEach(viewModel.documents) { document in
                MyDocumentCard(document: document) { onNavigate(document.linkRoute) }
            }
        }
    }
}

/// 07-4 상태 · 유형 칩 두 줄
private struct MyDocumentFilters: View {
    @Bindable var viewModel: MyDocumentsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            FlowLayout(spacing: Spacing.xs) {
                ForEach(Array(viewModel.statusFilters.enumerated()), id: \.offset) { _, status in
                    FilterChip(title: viewModel.statusTitle(status), isSelected: viewModel.statusFilter == status) {
                        viewModel.statusFilter = status
                    }
                }
            }
            FilterChipBar(
                items: viewModel.kindFilters,
                selection: viewModel.kindFilter,
                title: { viewModel.kindTitle($0) },
                onSelect: { viewModel.kindFilter = $0 }
            )
        }
    }
}

/// 07-4 문서 카드
private struct MyDocumentCard: View {
    let document: MyDocument
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(document.headerText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: document.status, size: .small)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(document.title)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(document.progressText)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            WorkspaceLinkRow(title: document.linkTitle, action: onOpen)
        }
    }
}

#Preview {
    NavigationStack {
        MyDocumentsView(viewModel: DIContainer.preview().makeMyDocumentsViewModel(), onNavigate: { _ in })
    }
}
