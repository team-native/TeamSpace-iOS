import SwiftUI

/// 06-1 상단 — TEAM LIBRARY + 제목
struct LibraryHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Circle()
                    .fill(Color.tsPrimary)
                    .frame(width: 5, height: 5)
                Text("TEAM LIBRARY")
                    .tsFont(.micro)
                    .foregroundStyle(Color.tsPrimary)
            }
            Text("팀의 기준을\n한곳에서 찾아요.")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// 06-1 검색창 모양 버튼 — 누르면 06-2 문서 검색으로 이동
struct LibrarySearchBar: View {
    var body: some View {
        HStack(spacing: Spacing.sm) {
            TSIcon.search.sized(.base)
                .foregroundStyle(Color.tsInk3)
            Text("찾고 싶은 문서를 검색해 보세요")
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .frame(height: 44)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .contentShape(Rectangle())
    }
}

/// 06-1 분류 카드 2×2
struct LibraryCategoryGrid: View {
    @Bindable var viewModel: LibraryViewModel

    private let columns = [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(LibraryFilter.allCases) { filter in
                Button { viewModel.filter = filter } label: {
                    LibraryCategoryCard(
                        filter: filter,
                        count: viewModel.count(of: filter),
                        isSelected: viewModel.filter == filter
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(viewModel.filter == filter ? .isSelected : [])
            }
        }
    }
}

private struct LibraryCategoryCard: View {
    let filter: LibraryFilter
    let count: Int
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                filter.icon.sized(.base)
                    .foregroundStyle(isSelected ? Color.tsPrimary : Color.tsInk2)
                Text(filter.title)
                    .tsFont(.captionBold)
                    .foregroundStyle(isSelected ? Color.tsPrimary : Color.tsInk)
            }
            Text("\(count)")
                .tsFont(.caption2Bold)
                .foregroundStyle(isSelected ? Color.tsPrimary : Color.tsInk3)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .fill(isSelected ? Color.tsPrimarySoft : Color.tsSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .stroke(isSelected ? Color.tsPrimary : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// 06-1 최근 개정된 규칙 배너
struct RevisionBanner: View {
    let revision: LibraryRevision

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconTile(icon: .bell, iconSize: .lg, tileSize: 36, tint: .tsOnPrimary, background: .tsPrimary)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text("최근 개정된 규칙이 있어요")
                    .tsFont(.captionBold)
                    .foregroundStyle(Color.tsInk)
                Text(revision.bannerText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
            }
            Spacer(minLength: Spacing.sm)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md + Spacing.xxxs)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// 06-1 · 06-2 문서 목록 (제목 + 개수 + 카드)
struct LibraryDocumentSection: View {
    let title: String
    let countText: String?
    let documents: [LibraryDocument]
    let onOpen: (LibraryDocument) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(title)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Spacer()
                if let countText {
                    Text(countText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            if documents.isEmpty {
                InfoBanner(message: "아직 이 분류에 등록된 문서가 없어요.", icon: .infoCircle, style: .muted)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(documents.enumerated()), id: \.element.id) { index, document in
                        if index > 0 { TSDivider() }
                        Button { onOpen(document) } label: { LibraryDocumentRow(document: document) }
                            .buttonStyle(.plain)
                    }
                }
                .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
            }
        }
    }
}

/// 문서 한 줄 — 분류 배지 · 날짜 · 제목 · 요약(검색 결과면 본문 일부)
struct LibraryDocumentRow: View {
    let document: LibraryDocument

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    StatusBadge(status: document.category, size: .small)
                    Text(TSFormat.fullDate(document.updatedAt))
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text(document.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                    .lineLimit(1)
                Text(document.excerpt ?? document.summary)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.sm)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(Spacing.lg)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
