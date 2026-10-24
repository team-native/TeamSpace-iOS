import SwiftUI

/// 아직 만들지 않은 탭 · 화면 자리
struct ComingSoonView: View {
    let title: String
    let showsBackButton: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer()
            VStack(spacing: Spacing.md) {
                TSIcon.clock.image
                    .tsIconSize(.hero)
                    .foregroundStyle(Color.tsPrimary)
                Text("곧 만나요")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                Text("\(title) 화면은 다음 작업에서 만들어요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
            }
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.bottom, Spacing.tabBarInset)
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            if showsBackButton {
                CircleIconButton(icon: .chevronLeft, accessibilityLabel: "뒤로", background: .tsSurface) { dismiss() }
            }
            Text(title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
        }
        .frame(height: 48)
    }
}

#Preview {
    ComingSoonView(title: "재무", showsBackButton: false)
}
