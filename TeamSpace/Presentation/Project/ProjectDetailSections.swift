import SwiftUI

/// 08-2 상단 — 상태 · 모집 배지 · 이름 · 설명
struct ProjectDetailHeader: View {
    let project: ProjectSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: project.status, size: .small)
                if project.isRecruiting {
                    StatusBadge(title: "인원 모집 중", tone: .negative, size: .small)
                }
            }
            Text(project.name)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(project.summary)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk2)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 08-2 진행률 카드
struct ProjectProgressCard: View {
    let project: ProjectSummary

    var body: some View {
        WorkspaceCard {
            HStack {
                Text("진행률")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
                Spacer()
                Text("\(project.progress)%")
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            TSProgressBar(percent: project.progress)
            HStack {
                Text("\(TSFormat.shortDate(project.startDate)) 시작")
                Spacer()
                Text("\(TSFormat.shortDate(project.endDate)) \(project.status == .completed ? "완료" : "출시 예정")")
            }
            .tsFont(.caption2)
            .foregroundStyle(Color.tsInk3)
        }
    }
}

/// 08-2 PM · 담당 부서 · 기간 · 참여 인원
struct ProjectInfoCard: View {
    let project: ProjectSummary

    var body: some View {
        WorkspaceCard {
            ProjectInfoRow(title: "PM", value: project.pmName)
            TSDivider()
            ProjectInfoRow(title: "담당 부서", value: project.department)
            TSDivider()
            ProjectInfoRow(title: "기간", value: project.periodText)
            TSDivider()
            ProjectInfoRow(title: "참여 인원", value: "\(project.memberCount)명")
        }
    }
}

private struct ProjectInfoRow: View {
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
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
    }
}

/// 08-2 함께하는 사람
struct ProjectMembersRow: View {
    let members: [ProjectMember]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("함께하는 사람")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.lg) {
                    ForEach(members) { member in
                        VStack(spacing: Spacing.xxs) {
                            AvatarView(size: 52)
                            Text(member.name)
                                .tsFont(.caption2Bold)
                                .foregroundStyle(Color.tsInk)
                            Text(member.role)
                                .tsFont(.micro)
                                .foregroundStyle(Color.tsInk3)
                        }
                        .frame(minWidth: 64)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

/// 08-2 모집 중인 자리
struct ProjectOpeningCard: View {
    let opening: ProjectOpening

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("모집 중인 자리")
                .tsFont(.caption2Bold)
                .foregroundStyle(Color.tsPrimary)
            Text(opening.headline)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            Text(opening.description)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// 08-2 관련 문서 · 일정
struct ProjectRelatedCard: View {
    let items: [ProjectRelatedItem]
    let onOpen: (ProjectRelatedItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("관련 문서 · 일정")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { TSDivider() }
                    Button { onOpen(item) } label: { ProjectRelatedRow(item: item) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

private struct ProjectRelatedRow: View {
    let item: ProjectRelatedItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            IconTile(icon: item.kind == .schedule ? .calendar : .file, iconSize: .lg, tileSize: 40)
            Text(title)
                .tsFont(.calloutBold)
                .foregroundStyle(Color.tsInk)
            Spacer(minLength: Spacing.sm)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .frame(minHeight: 68)
        .contentShape(Rectangle())
    }

    /// 일정은 앞에 날짜를 붙여요. ("10.14 디자인 리뷰")
    private var title: String {
        guard item.kind == .schedule, let date = item.date else { return item.title }
        return "\(TSFormat.shortDate(date)) \(item.title)"
    }
}
