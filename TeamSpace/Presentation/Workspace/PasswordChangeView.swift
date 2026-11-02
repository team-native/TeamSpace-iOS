import SwiftUI

/// 07-14 설정 · 비밀번호 변경 — 현재 · 새 · 새 비밀번호 확인 (Figma 화면이 없어 설정 · 로그인 입력 스타일을 따라요)
struct PasswordChangeView: View {
    @State private var viewModel: PasswordChangeViewModel
    @State private var isCompletedAlertPresented = false

    @Environment(\.dismiss) private var dismiss

    init(viewModel: PasswordChangeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenTitle(title: "새 비밀번호를 정해 주세요", subtitle: "\(ChangePasswordUseCase.minimumLength)자 이상, 지금 비밀번호와 다르게 정해 주세요")
                fields
                    .tsCard(padding: Spacing.xl)
                if let message = viewModel.errorMessage {
                    HStack(spacing: Spacing.xs) {
                        TSIcon.info.image.tsIconSize(.md)
                        Text(message).tsFont(.footnoteMedium)
                    }
                    .foregroundStyle(Color.tsNegative)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("오류: \(message)")
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "비밀번호 변경", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(viewModel.isSaving ? "바꾸는 중…" : "비밀번호 바꾸기") { Task { await viewModel.submit() } }
                .buttonStyle(.tsPrimary)
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, Spacing.screen)
                .padding(.vertical, Spacing.md)
                .background(Color.tsSurface.ignoresSafeArea())
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.didChange) { _, changed in
            if changed { isCompletedAlertPresented = true }
        }
        .alert("비밀번호를 바꿨어요", isPresented: $isCompletedAlertPresented) {
            Button("확인") { dismiss() }
        } message: {
            Text("다음 로그인부터 새 비밀번호를 써 주세요.")
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            TSTextField(
                label: "현재 비밀번호", placeholder: "지금 쓰는 비밀번호", text: $viewModel.currentPassword,
                isSecure: true, textContentType: .password, submitLabel: .next
            )
            VStack(alignment: .leading, spacing: Spacing.xs) {
                TSTextField(
                    label: "새 비밀번호", placeholder: "\(ChangePasswordUseCase.minimumLength)자 이상", text: $viewModel.newPassword,
                    isSecure: true, hasError: viewModel.newPasswordHint != nil, textContentType: .newPassword, submitLabel: .next
                )
                hint(viewModel.newPasswordHint)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                TSTextField(
                    label: "새 비밀번호 확인", placeholder: "한 번 더 입력", text: $viewModel.confirmPassword,
                    isSecure: true, hasError: viewModel.confirmHint != nil, textContentType: .newPassword, submitLabel: .done,
                    onSubmit: { Task { await viewModel.submit() } }
                )
                hint(viewModel.confirmHint)
            }
        }
        .disabled(viewModel.isSaving)
    }

    @ViewBuilder
    private func hint(_ message: String?) -> some View {
        if let message {
            Text(message)
                .tsFont(.caption)
                .foregroundStyle(Color.tsNegative)
        }
    }
}

#Preview {
    NavigationStack {
        PasswordChangeView(viewModel: DIContainer.preview().makePasswordChangeViewModel())
    }
}
