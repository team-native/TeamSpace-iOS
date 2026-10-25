import SwiftUI

/// 02-2 알림 센터
struct NotificationCenterView: View {
    @State private var viewModel: NotificationCenterViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationCenterViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FilterChipBar(
                    items: viewModel.filters,
                    selection: viewModel.filter,
                    title: { $0.title },
                    count: { viewModel.unreadCount(for: $0) },
                    onSelect: { viewModel.filter = $0 }
                )
                readStatus
                content
                settingsLink
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "알림", onBack: { dismiss() }) {
                ReadAllButton(isEnabled: viewModel.hasUnread) {
                    Task { await viewModel.markAllAsRead() }
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert(viewModel.toastMessage ?? "", isPresented: toastBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    /// 02-4 미확인 · 확인 개수, 02-5 모두 확인한 상태
    @ViewBuilder
    private var readStatus: some View {
        if case .loaded = viewModel.state {
            let summary = viewModel.readSummary(for: viewModel.filter)
            NotificationReadSummary(unread: summary.unread, read: summary.read)
            if viewModel.isAllCaughtUp {
                AllCaughtUpCard()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 240)
        case .loaded:
            NotificationSectionList(
                sections: viewModel.sections(),
                onOpen: { notification in Task { await viewModel.markAsRead(notification) } },
                onReview: { notification in
                    Task { await viewModel.markAsRead(notification) }
                    onNavigate(.comingSoon(title: "결재"))
                },
                onOpenTarget: { notification in
                    Task { await viewModel.markAsRead(notification) }
                    onNavigate(.comingSoon(title: notification.type.targetTitle))
                }
            )
            NotificationReadNotice(filter: viewModel.filter)
        case .empty, .forbidden:
            NotificationEmptyView()
        case .failed(let error):
            NotificationErrorView(message: error.userMessage) {
                Task { await viewModel.load() }
            }
        }
    }

    private var settingsLink: some View {
        Button {
            onNavigate(.notificationSettings)
        } label: {
            HStack(spacing: Spacing.xs) {
                TSIcon.settings.sized(.mdLarge)
                Text("알림 설정 · 30일이 지난 알림은 자동으로 정리돼요")
                    .tsFont(.caption)
            }
            .foregroundStyle(Color.tsInk3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    private var toastBinding: Binding<Bool> {
        Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )
    }
}

/// Figma `read-all` — 연한 파란 캡슐 버튼
private struct ReadAllButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("모두 읽음")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsPrimary)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .padding(.vertical, Spacing.xs + 1)
                .background(Color.tsPrimarySoft, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

#Preview {
    NavigationStack {
        NotificationCenterView(viewModel: DIContainer.preview().makeNotificationCenterViewModel(), onNavigate: { _ in })
    }
}
