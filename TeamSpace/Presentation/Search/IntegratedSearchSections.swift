import SwiftUI

/// 13 분류 칩 — 줄이 넘치면 다음 줄로 내려가요.
struct SearchFilterChips: View {
    @Bindable var viewModel: IntegratedSearchViewModel

    var body: some View {
        FlowLayout(spacing: Spacing.xs, lineSpacing: Spacing.xs) {
            ForEach(SearchFilter.allCases, id: \.self) { filter in
                FilterChip(
                    title: filter.title,
                    count: viewModel.count(of: filter),
                    isSelected: viewModel.filter == filter,
                    action: { viewModel.filter = filter }
                )
            }
        }
    }
}

/// 13 묶음 — "문서·규정 · 2" + 카드들
struct SearchSectionView: View {
    let section: SearchSection
    let onOpen: (SearchHit) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("\(section.title) · \(section.count)")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            ForEach(section.hits) { hit in
                SearchHitCard(hit: hit) { onOpen(hit) }
            }
        }
    }
}

/// 13 결과 카드 — 배지 · 제목 · 설명 · 메타 + 이동 줄
struct SearchHitCard: View {
    let hit: SearchHit
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if hit.category == .people {
                    personHeader
                } else {
                    if let badge = hit.badgeTitle {
                        StatusBadge(title: badge, tone: .primary)
                    }
                    Text(hit.title)
                        .tsFont(hit.category == .projects ? .headline : .bodyBold)
                        .foregroundStyle(Color.tsInk)
                    if !hit.snippet.isEmpty {
                        Text(hit.snippet)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk2)
                            .lineLimit(2)
                    }
                    if !hit.metaText.isEmpty {
                        Text(hit.metaText)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                linkRow
            }
            .multilineTextAlignment(.leading)
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var personHeader: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                Text(hit.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(hit.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
            }
            Spacer(minLength: 0)
            if let badge = hit.badgeTitle {
                StatusBadge(title: badge, tone: .primary)
            }
        }
    }

    private var linkRow: some View {
        HStack(spacing: Spacing.sm) {
            Text(hit.linkTitle)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsPrimary)
            Spacer(minLength: 0)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsPrimary)
                .accessibilityHidden(true)
        }
        .frame(height: 44)
    }
}
