import SwiftUI

/// 07-1 나의 To-do 요약
struct WorkspaceTodoCard: View {
    let todo: WorkspaceTodoSummary
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard(background: .tsPrimarySoft) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("나의 To-do")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsPrimary)
                    Text("오늘 \(todo.todayCount)개")
                        .tsFont(.title1)
                        .foregroundStyle(Color.tsInk)
                }
                Spacer()
                StatusBadge(title: "완료 \(todo.completedCount)개", tone: .primary)
            }
            if !todo.todayTitles.isEmpty {
                Text(todo.todayTitles.joined(separator: " · "))
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .lineLimit(2)
            }
            Button("나의 To-do 열기", action: onOpen)
                .buttonStyle(.tsPrimary)
                .padding(.top, Spacing.xs)
        }
    }
}

/// 07-1 내 알림
struct WorkspaceNotificationCard: View {
    let notification: WorkspaceNotificationPreview
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내 알림")
            StatusBadge(title: "개인 업무 · 안읽음 \(notification.unreadCount)", tone: .primary)
            WorkspaceItemText(title: notification.title, meta: notification.subtitle)
            WorkspaceLinkRow(title: "내 알림 모두 보기", action: onOpen)
        }
    }
}

/// 07-1 받은 결재 + 내가 제출한 문서
struct WorkspaceApprovalCard: View {
    let received: WorkspaceApprovalPreview?
    let submitted: WorkspaceSubmittedDocument?
    let onReview: (Int) -> Void
    let onSubmitted: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "받은 결재 · \(received?.waitingCount ?? 0)건")
            if let received {
                WorkspaceItemText(title: received.title, meta: received.metaText)
                WorkspaceLinkRow(title: "요청 검토하기", action: { onReview(received.documentId) })
            } else {
                Text("지금 검토할 결재가 없어요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            TSDivider()
            WorkspaceCardTitle(title: "내가 제출한 문서")
            if let submitted {
                WorkspaceItemText(title: submitted.title, meta: submitted.metaText)
            } else {
                Text("아직 제출한 문서가 없어요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            WorkspaceLinkRow(title: "제출 문서 진행 상황", action: onSubmitted)
        }
    }
}

/// 07-1 참여 프로젝트
struct WorkspaceProjectsCard: View {
    let projects: [WorkspaceProject]
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "참여 프로젝트 · \(projects.count)개")
            ForEach(projects) { project in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(project.name)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsInk)
                        Spacer()
                        Text("\(project.progress)%")
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsPrimary)
                    }
                    Text(project.metaText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk2)
                    TSProgressBar(percent: project.progress)
                        .padding(.top, Spacing.xxs)
                }
                .accessibilityElement(children: .combine)
            }
            WorkspaceLinkRow(title: "참여 프로젝트 보기", action: onOpen)
        }
    }
}

/// 07-1 예정 일정
struct WorkspaceSchedulesCard: View {
    let schedules: [WorkspaceSchedule]
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "예정 일정")
            if schedules.isEmpty {
                Text("다가오는 일정이 없어요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(Array(schedules.enumerated()), id: \.element.id) { index, schedule in
                if index > 0 { TSDivider() }
                StatusBadge(title: schedule.badgeText, tone: schedule.scope.badgeTone)
                WorkspaceItemText(title: schedule.title, meta: schedule.metaText)
            }
            WorkspaceLinkRow(title: "내 일정 보기", action: onOpen)
        }
    }
}

/// 07-1 내가 남긴 기록 — 글 · 댓글 / 운영 제안 / 문의
struct WorkspaceRecordsCard: View {
    let records: WorkspaceRecords
    /// 이동할 화면 제목
    let onOpen: (String) -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내가 남긴 기록")
            WorkspaceLinkRow(title: "내 글 · 댓글", subtitle: records.postText) { onOpen("내가 쓴 게시글·댓글") }
            TSDivider()
            WorkspaceLinkRow(title: "내 운영 제안 · \(records.proposalCount)건", subtitle: records.proposalText) {
                onOpen("내가 작성한 운영 제안")
            }
            TSDivider()
            WorkspaceLinkRow(title: "내 문의 · \(records.inquiries.count)건", subtitle: records.inquiryText) {
                onOpen("내 문의")
            }
        }
    }
}
