import SwiftUI

/// Figma `segmented` — 회색 트랙 위 흰 캡슐이 선택 항목
struct TSSegmentedControl<Item: Hashable>: View {
    let items: [Item]
    let selection: Item
    let title: (Item) -> String
    let onSelect: (Item) -> Void

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: Spacing.compact) {
            ForEach(items, id: \.self) { item in
                let isSelected = item == selection
                Button {
                    onSelect(item)
                } label: {
                    Text(title(item))
                        .tsFont(isSelected ? .captionBold : .captionMedium)
                        .foregroundStyle(isSelected ? Color.tsInk : Color.tsInk3)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.tsSurface)
                                    .tsShadow(.card)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(Spacing.compact)
        .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: selection)
    }
}

#Preview {
    TSSegmentedControl(items: ["사용 가능", "Native 보유금"], selection: "사용 가능", title: { $0 }, onSelect: { _ in })
        .padding()
}
