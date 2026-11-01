import SwiftUI

/// Figma `topbar` / `탐색 막대` — 원형 뒤로가기 + 제목 + 오른쪽 버튼
struct TSNavigationBar<Trailing: View>: View {
    let title: String
    let onBack: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Spacing.sm + Spacing.xxxs) {
            CircleIconButton(
                icon: .chevronLeft,
                accessibilityLabel: "뒤로",
                background: .tsSurface,
                hasBorder: true,
                action: onBack
            )
            Text(title)
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            trailing()
        }
        .frame(height: 44)
    }
}

extension TSNavigationBar where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

#Preview {
    VStack {
        TSNavigationBar(title: "알림", onBack: {}) {
            Text("모두 읽음")
        }
        TSNavigationBar(title: "알림 설정", onBack: {})
    }
    .padding()
    .background(Color.tsBackground)
}
