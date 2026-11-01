import SwiftUI

/// 07-5 임시 저장 문서 카드 — 상태 · 내용 · 자동 저장 · 동기화 · 이어서 작성 / 삭제
struct DraftDocumentCard: View {
    let document: MyDocument
    let onResume: () -> Void
    let onDelete: () -> Void

    var body: some View {
        WorkspaceCard {
            Text(document.title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: "작성 중", tone: .neutral, size: .small)
                StatusBadge(title: "새 작성", tone: .primary, size: .small)
            }
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(document.draftKindText)
                if let summary = document.summary {
                    Text(summary).lineLimit(2)
                }
            }
            .tsFont(.footnote)
            .foregroundStyle(Color.tsInk2)
            VStack(spacing: Spacing.sm) {
                DraftInfoRow(title: "자동 저장", value: "\(TSFormat.fullDate(document.updatedAt)) \(TSFormat.time(document.updatedAt))")
                DraftInfoRow(title: "동기화", value: "완료 · 모든 기기에 반영")
            }
            VStack(spacing: Spacing.sm) {
                Button("이어서 작성", action: onResume)
                    .buttonStyle(.tsPrimary)
                Button("임시 문서 삭제", action: onDelete)
                    .buttonStyle(.tsSecondary)
            }
            .padding(.top, Spacing.xs)
        }
    }
}

private struct DraftInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .tsFont(.footnoteMedium)
                .foregroundStyle(Color.tsInk)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// 07-5 긴 문서는 웹에서 편하게
struct WebContinueCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("긴 문서는 웹에서 편하게")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            Text("Native 웹 → 내공간 → 임시 저장에서 같은 문서를 선택해 주세요. 다른 기기에서는 최신 동기화 시각을 확인한 뒤 이어 쓰세요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
