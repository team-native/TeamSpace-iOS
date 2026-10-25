import SwiftUI

/// 상태 · 분류 칩 + 이름 + 내용
struct ContractHeader: View {
    let detail: ContractDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(title: detail.contract.status.title, tone: detail.contract.status.tone)
                StatusBadge(title: detail.category, tone: .neutral)
            }
            Text(detail.contract.name)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text("\(detail.contract.title) · \(detail.clientName)")
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
    }
}

/// 계약 금액
struct ContractAmountCard: View {
    let amount: Int
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("계약 금액")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.compact) {
                Text(TSFormat.number(amount))
                    .tsFont(.amount)
                Text("원")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(Color.tsInk)
            Text(caption)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
        }
        .tsCard(padding: Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

/// 진행 단계 — 세로 타임라인
struct ContractStepsSection: View {
    let steps: [ContractStep]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("진행 단계")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepRow(step: step, caption: step.caption, isLast: index == steps.count - 1)
                }
            }
            .tsCard(padding: Spacing.xl)
        }
    }
}

private struct StepRow: View {
    let step: ContractStep
    let caption: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md + Spacing.xxxs) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.isDone ? Color.tsPrimary : Color.tsSurface)
                        .overlay { Circle().stroke(step.isDone ? Color.clear : Color.tsLine, lineWidth: 2) }
                    if step.isDone {
                        TSIcon.checkSmall.sized(.sm)
                            .foregroundStyle(Color.tsOnPrimary)
                    }
                }
                .frame(width: 20, height: 20)
                if !isLast {
                    Rectangle()
                        .fill(step.isDone ? Color.tsPrimary : Color.tsLine)
                        .frame(width: 2, height: 30)
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(step.title)
                    .tsFont(.footnoteBold)
                    .foregroundStyle(step.isDone ? Color.tsInk : Color.tsInk3)
                Text(caption)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(step.isDone ? "완료" : "진행 전")
    }
}

/// 이 금액의 풀 배분
struct ContractPoolSection: View {
    let pools: [FinancePool]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("이 금액의 풀 배분")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: 0) {
                ForEach(Array(pools.enumerated()), id: \.offset) { index, pool in
                    if index > 0 { TSDivider() }
                    SmallKeyValueRow(title: "\(pool.kind.title) \(pool.ratio)%", value: TSFormat.won(pool.amount))
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxs)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        }
    }
}

/// 관련 정보 — 담당 PM · 참여 인원 · 계약서
struct ContractRelatedSection: View {
    let detail: ContractDetail
    let onOpenDocument: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("관련 정보")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: 0) {
                SmallKeyValueRow(title: "담당 PM", value: detail.managerName)
                TSDivider()
                SmallKeyValueRow(title: "참여 인원", value: "\(detail.memberCount)명")
                if let document = detail.documentName {
                    TSDivider()
                    Button(action: onOpenDocument) {
                        HStack(spacing: Spacing.sm + Spacing.xxxs) {
                            TSIcon.file.sized(.base)
                                .foregroundStyle(Color.tsInk2)
                            Text(document)
                                .tsFont(.footnoteMedium)
                                .foregroundStyle(Color.tsInk)
                            Spacer(minLength: 0)
                            TSIcon.chevronRight.sized(.base)
                                .foregroundStyle(Color.tsInk3)
                        }
                        .padding(.vertical, Spacing.md + Spacing.xxxs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxs)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsSurface))
        }
    }
}

/// 13pt 작은 `항목 ······ 값` 행 (04-2)
struct SmallKeyValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk3)
            Spacer(minLength: Spacing.sm)
            Text(value)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
        }
        .padding(.vertical, Spacing.md + Spacing.compact)
        .accessibilityElement(children: .combine)
    }
}
