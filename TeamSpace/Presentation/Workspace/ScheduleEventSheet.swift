import SwiftUI

/// 07-9 일정 상세 (시트) — 날짜 · 시간 · 장소 · 참여자 + 불참 / 참석할게요
struct ScheduleEventSheet: View {
    let event: ScheduleEvent
    let onRespond: (ScheduleResponse) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    StatusBadge(title: event.badgeText, tone: event.scope.badgeTone, size: .small)
                    Text(event.title)
                        .tsFont(.headline)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()
                CircleIconButton(icon: .close, accessibilityLabel: "닫기", size: 28, background: .tsSurface2) { dismiss() }
            }
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.xl)
            TSDivider()
            VStack(alignment: .leading, spacing: 0) {
                ScheduleInfoLine(icon: .calendar, text: event.dayText)
                ScheduleInfoLine(icon: .clock, text: event.timeText)
                ScheduleInfoLine(icon: .mapPin, text: event.placeText)
                ScheduleInfoLine(icon: .users, text: event.peopleText)
            }
            .padding(.vertical, Spacing.xs)
            TSDivider()
            HStack(spacing: -Spacing.xs) {
                ForEach(0..<min(event.participantCount, 6), id: \.self) { _ in
                    AvatarView(size: 29)
                        .padding(2)
                        .background(Color.tsSurface, in: Circle())
                }
            }
            .padding(.vertical, Spacing.lg)
            HStack(spacing: Spacing.sm) {
                Button("불참") { onRespond(.decline) }
                    .buttonStyle(.tsSecondary)
                Button(event.myResponse == .attend ? "참석 예정이에요" : "참석할게요") { onRespond(.attend) }
                    .buttonStyle(.tsPrimary)
            }
        }
        .padding(.horizontal, Spacing.xxl)
        .padding(.bottom, Spacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.tsSurface)
    }
}

/// 아이콘 + 한 줄 정보
struct ScheduleInfoLine: View {
    let icon: TSIcon
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            icon.sized(.base)
                .foregroundStyle(Color.tsInk3)
                .accessibilityHidden(true)
            Text(text)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk)
        }
        .frame(height: 41)
    }
}
