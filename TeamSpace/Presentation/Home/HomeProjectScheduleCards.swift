import SwiftUI

/// 02-1 진행 중인 프로젝트 카드
struct HomeProjectCard: View {
    let projects: [ProjectProgress]
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
            CardSectionHeader(title: "진행 중인 프로젝트", count: projects.count, linkTitle: "전체 보기", onLink: onShowAll)
            ForEach(projects) { project in
                VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
                    HStack {
                        Text(project.name)
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                            .lineLimit(1)
                        Spacer(minLength: Spacing.sm)
                        TagChip(title: TSFormat.dDay(project.dueDate), tone: dDayTone(project.dueDate))
                    }
                    TSProgressBar(percent: project.progress)
                    HStack {
                        Text("팀원 \(project.memberCount)명 · 마감 \(TSFormat.monthDay(project.dueDate))")
                        Spacer(minLength: 0)
                        Text("\(project.progress)%")
                    }
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .tsCard(padding: Spacing.lg)
    }

    /// 마감 2주 이내는 주황색으로 강조
    private func dDayTone(_ date: Date) -> BadgeTone {
        date.timeIntervalSinceNow < 14 * 86_400 + 3_600 ? .warning : .neutral
    }
}

/// 02-1 주요 일정 카드
struct HomeScheduleCard: View {
    let schedules: [ScheduleItem]
    let onShowCalendar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardSectionHeader(title: "주요 일정", count: schedules.count, linkTitle: "캘린더", onLink: onShowCalendar)
                .padding(.vertical, Spacing.md)
            ForEach(Array(schedules.enumerated()), id: \.element.id) { index, schedule in
                if index > 0 { TSDivider() }
                ScheduleRow(schedule: schedule, isFirst: index == 0, action: onShowCalendar)
            }
        }
        .tsCard(padding: Spacing.lg)
    }
}

private struct ScheduleRow: View {
    let schedule: ScheduleItem
    let isFirst: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md + Spacing.xxxs) {
                VStack(spacing: 0) {
                    Text(TSFormat.month(schedule.startsAt))
                        .font(.system(size: 10, weight: .bold))
                    Text(TSFormat.day(schedule.startsAt))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(isFirst ? Color.tsPrimary : Color.tsAmber)
                .frame(width: 42, height: 42)
                .background(
                    isFirst ? Color.tsPrimarySoft : Color.tsAmberSoft,
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(schedule.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .lineLimit(1)
                    Text("\(TSFormat.weekday(schedule.startsAt)) · \(schedule.place)")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
                Spacer(minLength: 0)
                TSIcon.chevronRight.sized(.mdLarge)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.vertical, Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
