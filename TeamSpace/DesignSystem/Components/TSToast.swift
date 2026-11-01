import SwiftUI

/// Figma 10-11 · 07-12 토스트 — 위쪽에 잠깐 떴다가 사라지는 검정 알약
struct TSToast: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TSIcon.checkCircle.sized(.base)
                .foregroundStyle(Color.tsPositive)
            Text(message)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsOnInk)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 44)
        .background(Color.tsInk.opacity(0.92), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

/// `message` 가 생기면 토스트를 보여주고 `duration` 뒤에 nil 로 돌려놔요.
private struct TSToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: UInt64

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message {
                    TSToast(message: message)
                        .padding(.top, Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: message) {
                            UIAccessibility.post(notification: .announcement, argument: message)
                            try? await Task.sleep(nanoseconds: duration)
                            guard !Task.isCancelled else { return }
                            withAnimation { self.message = nil }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    /// 사용: `.tsToast($viewModel.toastMessage)`
    func tsToast(_ message: Binding<String?>, duration: UInt64 = 2_000_000_000) -> some View {
        modifier(TSToastModifier(message: message, duration: duration))
    }
}

#Preview {
    Color.tsBackground
        .tsToast(.constant("링크를 복사했어요"))
}
