import SwiftUI

/// 07-7 달력 카드 — 달 이동 · 요일 · 날짜 (일정이 있는 날은 아래 점)
struct MonthCalendarCard: View {
    let viewModel: ScheduleCalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text(viewModel.monthTitle)
                    .tsFont(.headline)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CircleIconButton(icon: .chevronLeft, accessibilityLabel: "이전 달", size: 32, background: .tsSurface2) {
                    Task { await viewModel.showMonth(offset: -1) }
                }
                CircleIconButton(icon: .chevronRight, accessibilityLabel: "다음 달", size: 32, background: .tsSurface2) {
                    Task { await viewModel.showMonth(offset: 1) }
                }
            }
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { index, name in
                    Text(name)
                        .tsFont(.caption2)
                        .foregroundStyle(Self.color(forColumn: index, default: .tsInk3))
                }
                ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
                    if let date = day.date {
                        CalendarDayCell(
                            date: date,
                            textColor: Self.color(forColumn: index % 7, default: .tsInk),
                            isSelected: viewModel.isSelected(date),
                            isToday: viewModel.isToday(date),
                            hasEvent: !viewModel.events(on: date).isEmpty,
                            onTap: { viewModel.select(date) }
                        )
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.sheet, style: .continuous))
    }

    /// 일요일은 빨강, 토요일은 파랑
    static func color(forColumn column: Int, default color: Color) -> Color {
        switch column {
        case 0: return .tsNegative
        case 6: return .tsPrimary
        default: return color
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let textColor: Color
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .tsFont(.captionBold)
                    .foregroundStyle(isSelected ? Color.tsOnPrimary : textColor)
                    .frame(width: 32, height: 32)
                    .background(background, in: Circle())
                Circle()
                    .fill(hasEvent && !isSelected ? Color.tsPrimary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TSFormat.monthDay(date))
        .accessibilityValue(hasEvent ? "일정 있음" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var background: Color {
        if isSelected { return .tsPrimary }
        if isToday { return .tsPrimarySoft }
        return .clear
    }
}
