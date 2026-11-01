import SwiftUI

/// 07-8 상단 — 설명 · 분류 배지 · 제목 · 요약
struct ScheduleDetailHeader: View {
    let detail: ScheduleEventDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("일정을 한눈에 쉽고 빠르게 확인하세요")
                .tsFont(.micro)
                .foregroundStyle(Color.tsPrimary)
            StatusBadge(title: "\(detail.event.scope.title) · \(detail.category)", tone: .primary, size: .small)
            Text(detail.event.title)
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(detail.summary)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 항목명(왼쪽 고정 폭) + 값
private struct ScheduleKeyValue: View {
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

/// 07-8 모임 정보
struct ScheduleMeetingInfoCard: View {
    let detail: ScheduleEventDetail

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "모임 정보")
            ScheduleKeyValue(title: "일시", value: detail.event.fullTimeText)
            ScheduleKeyValue(title: "장소", value: detail.event.placeText)
            ScheduleKeyValue(title: "주최", value: detail.host)
            ScheduleKeyValue(title: "참석 대상", value: detail.audience)
            ScheduleKeyValue(title: "진행", value: detail.facilitator)
        }
    }
}

/// 07-8 이번 회의 안건
struct ScheduleAgendaCard: View {
    let agenda: [ScheduleAgendaItem]
    let note: String?

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "이번 회의 안건")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(agenda.enumerated()), id: \.offset) { _, item in
                    Text(item.text)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
            }
            if let note {
                Text(note)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
        }
    }
}

/// 07-8 내 참석 여부 — 참석 · 불참 · 미정
struct ScheduleResponseCard: View {
    let selected: ScheduleResponse?
    let savedText: String?
    let onSelect: (ScheduleResponse) -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내 참석 여부")
            HStack(spacing: Spacing.xs) {
                ForEach(ScheduleResponse.selectable, id: \.self) { response in
                    FilterChip(title: response.title, isSelected: selected == response) { onSelect(response) }
                }
            }
            if let savedText {
                StatusBadge(title: savedText, tone: .positive, icon: .check, size: .small)
            }
            Text("응답은 주최자가 준비에 활용해요. 일정이 바뀌면 다시 응답할 수 있어요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
        }
    }
}

/// 07-8 관련 문서
struct ScheduleDocumentCard: View {
    let document: ScheduleRelatedDocument
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            Text("관련 문서 · \(document.owner) · \(TSFormat.shortDate(document.updatedAt)) 업데이트")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk2)
            Text(document.title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            WorkspaceLinkRow(title: "회의 자료 열기", action: onOpen)
        }
    }
}

/// 07-8 변경 이력 — 가장 최근 변경은 파란 글씨
struct ScheduleHistoryCard: View {
    let history: [ScheduleChange]
    let note: String?

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "변경 이력")
            ForEach(Array(history.enumerated()), id: \.offset) { index, change in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Circle()
                        .fill(index == 0 ? Color.tsPrimary : Color.tsLine)
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("\(change.title) · \(TSFormat.shortDate(change.changedAt)) \(TSFormat.time(change.changedAt))")
                            .tsFont(.footnoteBold)
                            .foregroundStyle(index == 0 ? Color.tsPrimary : Color.tsInk)
                        Text(change.detail)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            if let note {
                Text(note)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
            }
        }
    }
}

/// 07-8 내 리마인더
struct ScheduleReminderCard: View {
    let reminders: [ReminderTiming]
    let onEdit: () -> Void

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "내 리마인더")
            ScheduleKeyValue(title: "알림", value: ReminderTiming.summary(reminders))
            Button("리마인더 변경", action: onEdit)
                .buttonStyle(.tsSecondary)
        }
    }
}

/// 리마인더 고르기 시트
struct ReminderEditorSheet: View {
    @Bindable var viewModel: ScheduleDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("언제 알려드릴까요?")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            ForEach(ReminderTiming.selectable, id: \.self) { timing in
                Toggle(isOn: Binding(
                    get: { viewModel.draftReminders.contains(timing) },
                    set: { _ in viewModel.toggleReminder(timing) }
                )) {
                    Text(timing.title)
                        .tsFont(.body)
                        .foregroundStyle(Color.tsInk)
                }
                .tint(Color.tsPrimary)
            }
            Button("저장") { Task { await viewModel.saveReminders() } }
                .buttonStyle(.tsPrimary)
                .disabled(viewModel.isSaving)
        }
        .padding(Spacing.xxl)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.tsSurface)
    }
}
