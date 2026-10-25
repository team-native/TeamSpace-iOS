import SwiftUI

/// Figma 아이콘 타일 — 연한 배경 사각형(또는 원) 위 아이콘
struct IconTile: View {
    let icon: TSIcon
    var iconSize: TSIconSize = .xl
    var tileSize: CGFloat = 40
    var tint: Color = .tsPrimary
    var background: Color = .tsPrimarySoft
    var isCircle = false

    var body: some View {
        icon.sized(iconSize, weight: .semibold)
            .foregroundStyle(tint)
            .frame(width: tileSize, height: tileSize)
            .background(background, in: shape)
            .accessibilityHidden(true)
    }

    private var shape: AnyShape {
        isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}

#Preview {
    HStack {
        IconTile(icon: .clipboardCheck)
        IconTile(icon: .wallet, tint: .tsApricot, background: .tsApricotSoft)
        IconTile(icon: .bellRing, iconSize: .heroSmall, tileSize: 72, isCircle: true)
    }
}
