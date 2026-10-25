import SwiftUI

enum AuthRoute: Hashable {
    case accountRequest
    case requestComplete(AccountRequestReceipt)
}

/// 01 로그인 / 계정 흐름 — 로그인 → 계정 요청 → 요청 완료
struct AuthFlowView: View {
    let container: DIContainer
    /// 알림을 눌러 들어왔다면 로그인 화면에 돌아갈 위치를 보여줘요. (02-8)
    var entry: NotificationEntry?
    var onCancelEntry: () -> Void = {}
    let onLoginSucceeded: (AuthUser) -> Void

    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(
                viewModel: container.makeLoginViewModel(),
                passwordResetViewModel: container.makePasswordResetViewModel(),
                entry: entry,
                onCancelEntry: onCancelEntry,
                onLoginSucceeded: onLoginSucceeded,
                onRequestAccount: { path.append(.accountRequest) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .accountRequest:
            AccountRequestView(
                viewModel: container.makeAccountRequestViewModel(),
                onCompleted: { receipt in path.append(.requestComplete(receipt)) },
                onBackToLogin: { path.removeAll() }
            )
        case .requestComplete(let receipt):
            AccountRequestCompleteView(receipt: receipt, onBackToLogin: { path.removeAll() })
        }
    }
}

#Preview {
    AuthFlowView(container: .preview(), onLoginSucceeded: { _ in })
}
