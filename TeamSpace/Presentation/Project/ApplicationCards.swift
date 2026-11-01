import SwiftUI

/// 08-6 펼친 신청 카드 — 신청 내용 · 진행 단계 · 수정 문의 / 취소
struct ApplicationDetailCard: View {
    let application: ProjectApplication
    let onAskPM: () -> Void
    let onCancel: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        WorkspaceCard {
            Text(application.titleText)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            StatusBadge(status: application.status, size: .small)
            ApplicationRow(title: "신청일", value: "\(TSFormat.fullDate(application.appliedAt)) \(TSFormat.time(application.appliedAt))")
            ApplicationRow(title: "모집 인원", value: "\(application.headcount)명 · PM \(application.pmName)")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("내가 제출한 내용")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(application.message)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                if let url = application.portfolioUrl {
                    Text("작업물 · \(url)")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsPrimary)
                }
            }
            ApplicationSteps(steps: application.progressSteps)
            if application.status == .reviewing {
                WorkspaceNote(message: "검토가 시작되어 내용을 직접 수정할 수 없어요. 결과 확정 전까지 신청 취소는 가능해요. 수정이 필요하면 PM에게 문의해 주세요.")
            }
            if application.status.isCancelable {
                HStack(spacing: Spacing.sm) {
                    Button("PM에게 수정 문의", action: onAskPM).buttonStyle(.tsSecondary)
                    Button("신청 취소", action: onCancel).buttonStyle(.tsSecondary)
                }
            }
            WorkspaceLinkRow(title: "접기", action: onCollapse)
        }
    }
}

/// 08-6 접은 신청 카드
struct ApplicationCompactCard: View {
    let application: ProjectApplication
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(application.compactMeta)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: application.status, size: .small)
            }
            WorkspaceItemText(title: application.titleText, meta: application.compactDescription)
            WorkspaceLinkRow(title: linkTitle, action: onOpen)
        }
    }

    private var linkTitle: String {
        switch application.status {
        case .accepted: return "프로젝트로 이동"
        case .declined: return "결과 상세 보기"
        default: return "신청 내용 보기"
        }
    }
}

private struct ApplicationRow: View {
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

/// 신청 접수 → PM 검토 → 결과 안내
private struct ApplicationSteps: View {
    let steps: [(title: String, detail: String, isDone: Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Circle()
                        .fill(step.isDone ? Color.tsPrimary : Color.tsLine)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(step.title)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(step.isDone ? Color.tsPrimary : Color.tsInk)
                        Text(step.detail)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
