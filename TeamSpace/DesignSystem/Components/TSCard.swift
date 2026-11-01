import SwiftUI

/// Figma `card` — 흰 배경 + r20 + 카드 그림자
struct TSCardModifier: ViewModifier {
    var padding: CGFloat = Spacing.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .tsShadow(.card)
    }
}

extension View {
    func tsCard(padding: CGFloat = Spacing.card) -> some View {
        modifier(TSCardModifier(padding: padding))
    }
}

#Preview {
    Text("카드 내용")
        .tsCard()
        .padding()
        .background(Color.tsBackground)
}
