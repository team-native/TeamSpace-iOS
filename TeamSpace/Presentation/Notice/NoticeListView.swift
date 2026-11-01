import SwiftUI

/// 10-5 공지 · 지금 팀이 알아야 할 것들
struct NoticeListView: View {
    @State private var viewModel: NoticeListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: NoticeListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("지금 팀이 알아야 할 것들")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                    Text("Inspace · Native 전체 공지와 재무 · 규칙 업데이트예요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
                .padding(.top, Spacing.sm)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(NoticeFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.title, isSelected: viewModel.filter == filter) { viewModel.filter = filter }
                        }
                    }
                    .padding(1)
                }
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var navigationBar: some View {
        TSNavigationBar(title: "공지", onBack: { dismiss() }) {
            if viewModel.canPublish {
                CircleIconButton(icon: .pencil, accessibilityLabel: "전체 공지 작성", background: .tsSurface, hasBorder: true) {
                    onNavigate(.noticeCompose)
                }
            }
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.bottom, Spacing.sm)
        .background(Color.tsBackground)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "공지를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.notices.isEmpty {
                InfoBanner(message: "이 분류의 공지가 아직 없어요.", style: .muted)
            }
            ForEach(viewModel.notices) { notice in
                NoticeCard(notice: notice) { onNavigate(.noticeDetail(id: notice.id)) }
            }
        }
    }
}

/// 10-5 공지 카드 — 분류 · 고정/날짜 · 제목
private struct NoticeCard: View {
    let notice: NoticeSummary
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        StatusBadge(status: notice.category, size: .small)
                        Text(notice.dateText())
                            .tsFont(.caption2)
                            .foregroundStyle(notice.isPinned ? Color.tsPrimary : Color.tsInk3)
                    }
                    Text(notice.title)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: Spacing.sm)
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        NoticeListView(
            viewModel: DIContainer.preview().makeNoticeListViewModel(user: AuthUser(id: 1, name: "김민준", roles: [.fa])),
            onNavigate: { _ in }
        )
    }
}
