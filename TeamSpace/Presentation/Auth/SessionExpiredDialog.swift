import SwiftUI

/// Figma 01-6 로그인 만료 안내 — 앱을 쓰다가 리프레시 토큰까지 만료되면 로그인 화면 위에 띄워요.
struct SessionExpiredDialog: View {
    let onConfirm: () -> Void

    var body: some View {
        TSDialog(onDismiss: onConfirm) {
            VStack(spacing: Spacing.lg) {
                VStack(spacing: Spacing.sm) {
                    TSIcon.lock.sized(.xlLarge)
                        .foregroundStyle(Color.tsPrimary)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Color.tsPrimarySoft))
                        .accessibilityHidden(true)
                        .padding(.bottom, Spacing.xxs)
                    Text("로그인이 만료됐어요")
                        .tsFont(.headline)
                        .foregroundStyle(Color.tsInk)
                    Text("보안을 위해 다시 로그인해 주세요.\n작성 중이던 내용은 저장되지 않았을 수 있어요.")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
                Button("다시 로그인", action: onConfirm)
                    .buttonStyle(.tsPrimary)
            }
            .padding(Spacing.xxl)
        }
    }
}

#Preview {
    SessionExpiredDialog(onConfirm: {})
}
