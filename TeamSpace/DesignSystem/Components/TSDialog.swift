import SwiftUI

/// Figma 커스텀 알림창 (05-9 승인 확인 · 05-10 처리 완료) — 어두운 배경 + 가운데 흰 카드
struct TSDialog<Content: View>: View {
    var onDismiss: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.tsScrim.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss?() }
                .accessibilityHidden(true)
            content()
                .frame(maxWidth: 350)
                .background(RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous).fill(Color.tsSurface))
                .clipShape(RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
                .tsShadow(.raised)
                .padding(.horizontal, Spacing.screen)
                .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

#Preview {
    TSDialog {
        VStack(spacing: Spacing.lg) {
            Text("이 요청을 승인할까요?").tsFont(.headline)
            Button("승인") {}.buttonStyle(.tsPrimary)
        }
        .padding(Spacing.xxl)
    }
}
