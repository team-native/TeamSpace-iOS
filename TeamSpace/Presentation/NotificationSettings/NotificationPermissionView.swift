import SwiftUI

/// 02-6 알림 권한 안내
struct NotificationPermissionView: View {
    @State private var viewModel: NotificationPermissionViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: NotificationPermissionViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                IconTile(icon: .bellRing, iconSize: .heroSmall, tileSize: 64, isCircle: true)
                ScreenTitle(
                    title: "필요한 순간에 알고,\n바로 처리해요.",
                    subtitle: "결재 요청 · 재정 승인 · 일정처럼 놓치면 안 되는 소식만 골라 알려드려요."
                )
                NotificationPreviewCard(hidesSensitive: viewModel.lockScreenPreview == .hideSensitive)
                NotificationTopicList()
                LockScreenPreviewPicker(
                    options: viewModel.previewOptions,
                    selection: viewModel.lockScreenPreview,
                    onSelect: { option in Task { await viewModel.select(option) } }
                )
                InfoBanner(
                    message: "받을 알림 종류는 언제든 알림 설정에서 바꿀 수 있어요.",
                    icon: .infoCircle,
                    style: .muted
                )
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "알림 권한", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.xs) {
            Button {
                Task { await requestPermission() }
            } label: {
                if viewModel.isRequesting {
                    ProgressView().tint(Color.tsOnPrimary)
                } else {
                    Text("알림 허용하기")
                }
            }
            .buttonStyle(.tsPrimaryLarge)
            .disabled(viewModel.isRequesting)

            Button("나중에") { dismiss() }
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk3)
                .padding(.vertical, Spacing.sm)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.md)
        .background(Color.tsBackground)
    }

    private func requestPermission() async {
        switch await viewModel.requestPermission() {
        case .authorized:
            dismiss()
        case .denied:
            onNavigate(.notificationTroubleshoot)
        case .notDetermined, .none:
            break
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        NotificationPermissionView(
            viewModel: DIContainer.preview().makeNotificationPermissionViewModel(),
            onNavigate: { _ in }
        )
    }
}
