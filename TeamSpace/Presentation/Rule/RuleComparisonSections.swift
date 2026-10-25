import SwiftUI

/// 09-4 상단 — 읽음 상태 배지 · 제목 · v1.2 → v1.3 · 시행일 · 개정일 · 담당 부서
struct RuleComparisonHeader: View {
    let detail: RuleDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            StatusBadge(title: detail.comparisonBadgeTitle, tone: detail.acknowledgedAt == nil ? .primary : .positive, size: .small)
            Text(detail.rule.title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.xs) {
                if let previous = detail.previousVersion {
                    StatusBadge(title: previous, tone: .neutral, size: .small)
                    Text("→")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                StatusBadge(title: detail.rule.version, tone: .primary, size: .small)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.top, Spacing.sm)
        WorkspaceCard {
            RuleComparisonInfoRow(title: "시행일", value: TSFormat.fullDate(detail.rule.effectiveAt))
            RuleComparisonInfoRow(title: "최근 개정일", value: TSFormat.fullDate(detail.rule.revisedAt))
            RuleComparisonInfoRow(title: "담당 부서", value: detail.rule.department)
            if let summary = detail.rule.changeSummary {
                Text("‘\(summary)’ 변경을 비교해요.")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
        }
    }
}

private struct RuleComparisonInfoRow: View {
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

/// 바뀐 조항 — 이전 본문(회색) · 변경 후 본문(파랑) · 핵심 변경 · 사유
struct RuleChangedArticleCard: View {
    let article: RuleArticle
    let previousVersion: String?
    let version: String

    var body: some View {
        WorkspaceCard {
            Text("제\(article.number)조 · \(article.title)")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            if let comparison = article.comparison {
                StatusBadge(title: comparison.label, tone: .primary, size: .small)
                RuleBodyBox(title: "이전 · \(previousVersion ?? "이전 버전")", text: comparison.previousBody, isAfter: false)
                RuleBodyBox(title: "변경 후 · \(version)", text: article.body, isAfter: true)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(comparison.highlight)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    if let reason = comparison.reason {
                        Text("개정 사유: \(reason)")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct RuleBodyBox: View {
    let title: String
    let text: String
    let isAfter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .tsFont(.caption2Bold)
                .foregroundStyle(isAfter ? Color.tsPrimary : Color.tsInk3)
            Text(text)
                .tsFont(.footnote)
                .foregroundStyle(isAfter ? Color.tsInk : Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isAfter ? Color.tsPrimarySoft : Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// 변경하지 않은 조항 — 이전 / 변경 후 동일
struct RuleUnchangedArticlesCard: View {
    let articles: [RuleArticle]

    var body: some View {
        if !articles.isEmpty {
            WorkspaceCard {
                WorkspaceCardTitle(title: "변경하지 않은 조항")
                ForEach(articles) { article in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("제\(article.number)조 · \(article.title)")
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsInk)
                        Text("이전 / 변경 후 동일: \(article.body)")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}
