import SwiftUI

/// 07-12 내 활동 — 숫자 네 칸, 누르면 각 목록으로
struct ActivitySummaryView: View {
    @State private var viewModel: ActivitySummaryViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ActivitySummaryViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    private let columns = [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("활동 요약")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk3)
                    .padding(.top, Spacing.md)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 활동", onBack: { dismiss() })
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
            InfoBanner(message: "내 활동을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let summary):
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ActivityTile(count: summary.unreadNotificationCount, title: "안 읽은 알림") { onNavigate(.notificationCenter) }
                ActivityTile(count: summary.submittedDocumentCount, title: "제출한 문서") { onNavigate(.workspaceDocuments) }
                ActivityTile(count: summary.postCount, title: "작성한 게시글") { onNavigate(.board) }
                ActivityTile(count: summary.inquiryCount, title: "작성한 문의") { onNavigate(.comingSoon(title: "내 문의")) }
            }
        }
    }
}

private struct ActivityTile: View {
    let count: Int
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(count)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.tsInk)
                Text(title)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .bottomLeading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ActivitySummaryView(viewModel: DIContainer.preview().makeActivitySummaryViewModel(), onNavigate: { _ in })
    }
}
