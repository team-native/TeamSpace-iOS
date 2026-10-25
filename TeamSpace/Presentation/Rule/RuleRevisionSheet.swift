import SwiftUI

/// 09-3 변경 내역 (시트) — 버전 · 날짜 · 바뀐 조항 · 담당 부서 · 작성자
struct RuleRevisionSheet: View {
    let revisions: [RuleRevision]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("변경 내역")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CircleIconButton(icon: .close, accessibilityLabel: "닫기", size: 32) { dismiss() }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(revisions.enumerated()), id: \.element.id) { index, revision in
                        RuleRevisionRow(revision: revision, isLast: index == revisions.count - 1)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.xl)
        .background(Color.tsSurface.ignoresSafeArea())
    }
}

/// 타임라인 한 줄 — 마지막(최초 제정)은 회색 점
private struct RuleRevisionRow: View {
    let revision: RuleRevision
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isLast ? Color.tsInk3 : Color.tsPrimary)
                    .frame(width: 8, height: 8)
                    .padding(.top, Spacing.xxs)
                if !isLast {
                    Rectangle()
                        .fill(Color.tsLine)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(revision.version)
                        .tsFont(.caption2Bold)
                        .foregroundStyle(isLast ? Color.tsInk3 : Color.tsPrimary)
                    Text(TSFormat.fullDate(revision.revisedAt))
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Text(revision.summary)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text("\(revision.department) · \(revision.author)")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.bottom, isLast ? 0 : Spacing.lg)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RuleRevisionSheet(revisions: [
        RuleRevision(version: "v1.3", revisedAt: Date(), summary: "제2조 검토 기한 3주 → 2주", department: "NativeOps", author: "안율"),
        RuleRevision(version: "v1.0", revisedAt: Date(), summary: "최초 제정", department: "Leader", author: "김민준")
    ])
}
