import SwiftUI

/// Figma `card-header` — 파란 점 + 제목 (+ 개수) + 오른쪽 링크
struct CardSectionHeader: View {
    let title: String
    var count: Int?
    var linkTitle: String?
    var onLink: (() -> Void)?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(Color.tsPrimary)
                .frame(width: 7, height: 7)
            Text(title)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            if let count {
                Text("\(count)건")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: 0)
            if let linkTitle, let onLink {
                Button(linkTitle, action: onLink)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .buttonStyle(.plain)
            }
        }
    }
}

/// Figma 카드 밖 섹션 제목 (`필요한 일에 바로`, `지금 팀이 알아야 할 것들`)
struct SectionTitle: View {
    let title: String
    var linkTitle: String?
    var onLink: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let linkTitle, let onLink {
                Button(action: onLink) {
                    HStack(spacing: Spacing.compact) {
                        Text(linkTitle)
                            .tsFont(.caption)
                        TSIcon.chevronRight.sized(.sm)
                    }
                    .foregroundStyle(Color.tsInk3)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        CardSectionHeader(title: "진행 중인 프로젝트", count: 2, linkTitle: "전체 보기", onLink: {})
        SectionTitle(title: "지금 팀이 알아야 할 것들", linkTitle: "전체 보기", onLink: {})
    }
    .padding()
}
