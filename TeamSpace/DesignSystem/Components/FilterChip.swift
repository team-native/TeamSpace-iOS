import SwiftUI

/// Figma `filter/~` — 선택 시 파란 배경, 아니면 흰 배경 + 테두리. 숫자(count)는 선택 사항
struct FilterChip: View {
    let title: String
    var count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs + 1) {
                Text(title)
                    .tsFont(isSelected ? .captionBold : .captionMedium)
                if let count {
                    Text("\(count)")
                        .tsFont(.caption2)
                        .opacity(isSelected ? 0.8 : 1)
                        .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk3)
                }
            }
            .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk2)
            .padding(.horizontal, Spacing.md + Spacing.xxxs)
            .frame(height: 30)
            .background(isSelected ? Color.tsPrimary : Color.tsSurface, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.tsLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 가로 스크롤 칩 묶음
struct FilterChipBar<Item: Hashable>: View {
    let items: [Item]
    let selection: Item
    let title: (Item) -> String
    var count: (Item) -> Int? = { _ in nil }
    let onSelect: (Item) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(items, id: \.self) { item in
                    FilterChip(
                        title: title(item),
                        count: count(item),
                        isSelected: item == selection,
                        action: { onSelect(item) }
                    )
                }
            }
            .padding(1)
        }
    }
}

#Preview {
    FilterChipBar(
        items: ["전체", "내 업무", "재정", "일정", "공지"],
        selection: "전체",
        title: { $0 },
        count: { $0 == "전체" ? 6 : nil },
        onSelect: { _ in }
    )
    .padding()
}
