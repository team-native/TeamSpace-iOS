import SwiftUI

/// 07-13 프로필 편집
struct ProfileEditView: View {
    @State private var viewModel: ProfileEditViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProfileEditViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            ProfileEditTopBar(
                canSave: viewModel.hasChanges && !viewModel.isSaving,
                onBack: { dismiss() },
                onSave: { Task { await viewModel.save() } }
            )
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .modifier(ProfileEditDialogs(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "프로필을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let profile):
            VStack(spacing: Spacing.md) {
                ProfileAvatar(imageData: viewModel.avatarImageData, background: viewModel.avatarBackground)
                Button("미모티콘 바꾸기") { viewModel.isAvatarMenuPresented = true }
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsOnPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: 36)
                    .background(Color.tsPrimary, in: Capsule())
                    .buttonStyle(.plain)
            }
            .padding(.top, Spacing.xl)
            ProfileEditFields(viewModel: viewModel, profile: profile)
            InfoBanner(
                message: "iPhone 메시지 앱 › 미모티콘 › 스티커를 길게 눌러 저장한 뒤 업로드하세요.",
                icon: .infoCircle,
                style: .muted
            )
        }
    }
}

/// 07-13 상단 — 뒤로 · 제목 · 저장
private struct ProfileEditTopBar: View {
    let canSave: Bool
    let onBack: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            Text("프로필 편집")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            HStack {
                CircleIconButton(icon: .chevronLeft, accessibilityLabel: "뒤로", background: .tsSurface, hasBorder: true, action: onBack)
                Spacer()
                Button("저장", action: onSave)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsOnPrimary)
                    .padding(.horizontal, Spacing.md + Spacing.xxxs)
                    .frame(height: 32)
                    .background(Color.tsPrimary, in: Capsule())
                    .opacity(canSave ? 1 : 0.45)
                    .buttonStyle(.plain)
                    .disabled(!canSave)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.screen)
        .padding(.bottom, Spacing.sm)
        .background(Color.tsBackground)
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(viewModel: DIContainer.preview().makeProfileEditViewModel())
    }
}
