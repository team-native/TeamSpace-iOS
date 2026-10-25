import SwiftUI

/// 08-8 프로젝트 마일스톤 — 완료 · 진행 중은 파랑
struct MilestoneCard: View {
    let milestones: [ProjectMilestone]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "프로젝트 마일스톤")
            ForEach(Array(milestones.enumerated()), id: \.offset) { _, milestone in
                let isActive = milestone.state == .done || milestone.state == .current
                HStack(alignment: .top, spacing: Spacing.md) {
                    Circle()
                        .fill(isActive ? Color.tsPrimary : Color.tsLine)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(milestone.title)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(isActive ? Color.tsPrimary : Color.tsInk)
                        Text(milestone.detailText)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 08-8 내 일정 — 이 프로젝트에서 내가 참석하는 일정
struct MyProjectSchedulesCard: View {
    let schedules: [ProjectMySchedule]
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내 일정")
            if schedules.isEmpty {
                Text("이 프로젝트에서 참석할 일정이 없어요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(schedules) { schedule in
                WorkspaceItemText(
                    title: schedule.title,
                    meta: "\(TSFormat.shortDate(schedule.startsAt)) \(TSFormat.timeRange(schedule.startsAt, schedule.endsAt)) · \(schedule.place)"
                )
            }
            if !schedules.isEmpty {
                WorkspaceLinkRow(title: "내 일정 전체 보기", action: onOpen)
            }
        }
    }
}

/// 항목명 + 값
private struct ChangeRow: View {
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

/// 08-8 가장 최근 일정 변경
struct LatestChangeCard: View {
    let change: ProjectScheduleChange
    let onOpenSchedule: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: change.title)
            StatusBadge(title: change.changedText, tone: .primary, size: .small)
            ChangeRow(title: "변경 전", value: change.beforeText)
            ChangeRow(title: "변경 후", value: change.afterText)
            ChangeRow(title: "장소", value: change.place)
            ChangeRow(title: "수정자", value: "\(change.editorName) · \(change.editorRole)")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("변경 사유")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(change.reason)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
            }
            StatusBadge(title: "참여자 \(change.notifiedCount)명 · 알림 생성 완료", tone: .positive, icon: .check, size: .small)
            Text("개인 업무 알림으로 전달했어요. 생성 완료는 모든 참여자의 읽음이나 푸시 수신을 뜻하지 않아요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            Button("내 일정에서 확인", action: onOpenSchedule)
                .buttonStyle(.tsPrimary)
        }
    }
}

/// 08-8 지난 변경 — "이전 변경 자세히" 로 펼쳐요.
struct OlderChangeCard: View {
    let change: ProjectScheduleChange
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        WorkspaceCard {
            Text("\(TSFormat.shortDate(change.changedAt)) · 수정자 \(change.editorName)")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk2)
            WorkspaceItemText(title: change.title, meta: change.summaryText)
            if isExpanded {
                ChangeRow(title: "변경 전", value: change.beforeText)
                ChangeRow(title: "변경 후", value: change.afterText)
                ChangeRow(title: "장소", value: change.place)
            }
            WorkspaceLinkRow(title: isExpanded ? "접기" : "이전 변경 자세히", action: onToggle)
        }
    }
}
