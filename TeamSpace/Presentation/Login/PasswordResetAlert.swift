import SwiftUI

/// 01-4 비밀번호 찾기 — 이메일 입력 Alert + 결과 Alert
struct PasswordResetAlert: ViewModifier {
    @Bindable var viewModel: PasswordResetViewModel

    func body(content: Content) -> some View {
        content
            .alert("비밀번호 찾기", isPresented: $viewModel.isInputPresented) {
                TextField("s00000@gsm.hs.kr", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                Button("취소", role: .cancel) {}
                Button("보내기") {
                    Task { await viewModel.send() }
                }
                .disabled(!viewModel.canSend)
            } message: {
                Text("가입한 이메일로 재설정 링크를 보내드려요.")
            }
            .alert(viewModel.resultTitle, isPresented: isResultPresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.resultMessage ?? "")
            }
    }

    private var isResultPresented: Binding<Bool> {
        Binding(
            get: { viewModel.resultMessage != nil },
            set: { if !$0 { viewModel.dismissResult() } }
        )
    }
}

extension View {
    func passwordResetAlert(_ viewModel: PasswordResetViewModel) -> some View {
        modifier(PasswordResetAlert(viewModel: viewModel))
    }
}
