import SwiftUI

/// 09-2 상단 — RULE · 최근 개정 배지, 제목, 시행일 · 개정일 · 담당 부서 · 변경 내역
struct RuleDetailHeader: View {
    let rule: RuleSummary
    let onShowRevisions: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: LibraryCategory.rule, size: .small)
                if rule.isRecentlyRevised() {
                    StatusBadge(title: "최근 개정", tone: .negative, size: .small)
                }
            }
            Text(rule.title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, Spacing.sm)
        WorkspaceCard {
            RuleInfoRow(title: "시행일", value: TSFormat.fullDate(rule.effectiveAt))
            RuleInfoRow(title: "최근 개정일", value: TSFormat.fullDate(rule.revisedAt))
            RuleInfoRow(title: "담당 부서", value: rule.department)
            Button(action: onShowRevisions) {
                HStack {
                    Text("변경 내역")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                    Spacer()
                    Text("\(rule.revisionCount)건 보기")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsPrimary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct RuleInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
            Spacer()
            Text(value)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 조항 바로가기 칩 ("1. 목적")
struct RuleArticleChips: View {
    let articles: [RuleArticle]
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(articles) { article in
                    FilterChip(title: "\(article.number). \(article.title)", isSelected: false) { onSelect(article.number) }
                }
            }
            .padding(1)
        }
    }
}

/// 조항 한 개 — 제N조 · 제목 · (개정) · 본문 · 바뀐 점
struct RuleArticleView: View {
    let article: RuleArticle

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Text("제\(article.number)조")
                    .tsFont(.caption2Bold)
                    .foregroundStyle(Color.tsPrimary)
                Text(article.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                if article.isRevised {
                    StatusBadge(title: "개정", tone: .negative, size: .small)
                }
            }
            .accessibilityAddTraits(.isHeader)
            Text(article.body)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
            if let note = article.changeNote {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("이번 개정에서 바뀐 점")
                        .tsFont(.caption2Bold)
                    Text(note)
                        .tsFont(.caption2)
                }
                .foregroundStyle(Color.tsPrimary)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
        }
    }
}

/// 09-2 아래 — 읽는 중 / 읽음 확인
struct RuleReadBar: View {
    let text: String
    let isAcknowledged: Bool
    let isLoading: Bool
    let onAcknowledge: () -> Void

    var body: some View {
        HStack {
            Text(text)
                .tsFont(.footnote)
                .foregroundStyle(isAcknowledged ? Color.tsPositive : Color.tsInk3)
            Spacer()
            if !isAcknowledged {
                Button("읽음 확인", action: onAcknowledge)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsOnPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: 36)
                    .background(Color.tsPrimary, in: Capsule())
                    .buttonStyle(.plain)
                    .disabled(isLoading)
            }
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.md)
        .background(Color.tsSurface.shadow(.drop(color: .black.opacity(0.05), radius: 8, y: -2)))
    }
}
