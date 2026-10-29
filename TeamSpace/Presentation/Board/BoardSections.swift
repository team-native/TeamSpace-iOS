import SwiftUI

/// 10-1 맨 위 검색창 — 누르면 10-12 검색으로 가요.
struct BoardSearchEntry: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                TSIcon.search.sized(.base)
                    .foregroundStyle(Color.tsInk3)
                Text("게시글 · 댓글 검색")
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk3)
                Spacer()
            }
            .padding(.horizontal, Spacing.md + Spacing.xxxs)
            .frame(height: 46)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("게시글 · 댓글 검색")
    }
}

/// 10-1 기간 칩 — 선택된 칩은 검정
struct BoardPeriodBar: View {
    let selection: BoardPeriod
    let onSelect: (BoardPeriod) -> Void
    let onCustom: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(BoardPeriod.presets, id: \.self) { period in
                    BoardPeriodChip(title: period.title, isSelected: selection == period) { onSelect(period) }
                }
                BoardPeriodChip(
                    title: selection.isCustom ? selection.title : "기간 설정",
                    icon: .calendar,
                    isSelected: selection.isCustom,
                    action: onCustom
                )
            }
            .padding(1)
        }
    }
}

private struct BoardPeriodChip: View {
    let title: String
    var icon: TSIcon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let icon {
                    icon.sized(.sm)
                }
                Text(title)
                    .tsFont(isSelected ? .captionBold : .captionMedium)
            }
            .foregroundStyle(isSelected ? Color.tsOnInk : Color.tsInk2)
            .padding(.horizontal, Spacing.md + Spacing.xxxs)
            .frame(height: 34)
            .background(isSelected ? Color.tsInk : Color.tsSurface, in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.tsLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 10-1 공식 문의 · 건의 배너 (11-2로 이동)
struct BoardInquiryBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                IconTile(icon: .megaphone, iconSize: .lg, tileSize: 36, background: .tsSurface)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("공식 문의 · 건의")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsPrimary)
                    Text("담당 부서에 직접 전달하고 처리 상태를 확인해요")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk2)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 10-1 "내 문의 3건 >" · 정렬
struct BoardListHeader: View {
    let inquiryCount: Int
    let sort: BoardSort
    let onOpenInquiries: () -> Void
    let onSort: (BoardSort) -> Void

    var body: some View {
        HStack {
            Button(action: onOpenInquiries) {
                HStack(spacing: Spacing.xs) {
                    Text("내 문의")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    StatusBadge(title: "\(inquiryCount)건", tone: .primaryFilled, size: .small)
                    TSIcon.chevronRight.sized(.sm)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Menu {
                ForEach(BoardSort.allCases, id: \.self) { option in
                    Button(option.title) { onSort(option) }
                }
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Text(sort.title)
                        .tsFont(.caption)
                    TSIcon.chevronDown.sized(.xs)
                }
                .foregroundStyle(Color.tsInk2)
            }
            .accessibilityLabel("정렬 \(sort.title)")
        }
    }
}

/// 10-1 분류 칩 — 전체 · 공지 · 자유 · 질문 · 정보공유
struct BoardFilterBar: View {
    let selection: BoardFilter
    let onSelect: (BoardFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(BoardFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.title, isSelected: selection == filter) { onSelect(filter) }
                }
            }
            .padding(1)
        }
    }
}

/// 10-1 글쓰기 플로팅 버튼
struct BoardWriteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                TSIcon.pencil.sized(.base, weight: .semibold)
                Text("글쓰기")
                    .tsFont(.calloutBold)
            }
            .foregroundStyle(Color.tsOnPrimary)
            .padding(.horizontal, Spacing.lg)
            .frame(height: 48)
            .background(Color.tsPrimary, in: Capsule())
            .tsShadow(.primaryGlow)
        }
        .buttonStyle(.plain)
    }
}
