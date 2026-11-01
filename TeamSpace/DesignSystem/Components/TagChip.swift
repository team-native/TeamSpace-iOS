import SwiftUI

/// Figma 작은 각진 칩 (`계약 완료`, `D-27` 등) — r5, 9~10pt
struct TagChip: View {
    let title: String
    var tone: BadgeTone = .neutral

    var body: some View {
        Text(title)
            .tsFont(.micro)
            .foregroundStyle(tone.foreground)
            .lineLimit(1)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(tone.background, in: RoundedRectangle(cornerRadius: Radius.xs, style: .continuous))
    }
}

/// Figma 둥근 카테고리 칩 (`재무`, `규칙`, `공지`)
struct CategoryChip: View {
    let title: String
    var tone: BadgeTone = .neutral

    var body: some View {
        Text(title)
            .tsFont(.micro)
            .foregroundStyle(tone.foreground)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.compact)
            .background(tone.background, in: Capsule())
    }
}

#Preview {
    HStack {
        TagChip(title: "계약 완료", tone: .primary)
        TagChip(title: "D-14", tone: .warning)
        CategoryChip(title: "재무", tone: .primary)
    }
}
