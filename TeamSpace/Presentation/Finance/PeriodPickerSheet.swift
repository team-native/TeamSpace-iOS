import SwiftUI

/// 04-4 기간 선택 (iOS Wheel Picker) — 연 · 월
struct PeriodPickerSheet: View {
    let onDone: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var year: Int
    @State private var month: Int

    private let years: [Int]
    private let calendar = Calendar.current

    init(selection: Date, onDone: @escaping (Date) -> Void) {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        self.onDone = onDone
        self.years = Array((currentYear - 3)...(currentYear + 2))
        _year = State(initialValue: calendar.component(.year, from: selection))
        _month = State(initialValue: calendar.component(.month, from: selection))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .tsFont(.body)
                    .foregroundStyle(Color.tsInk2)
                Spacer()
                Text("기간 선택")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Spacer()
                Button("완료") { onDone(selectedDate) }
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            .padding(.horizontal, Spacing.xl)
            .frame(height: 48)
            HStack(spacing: 0) {
                Picker("연도", selection: $year) {
                    ForEach(years, id: \.self) { Text("\(String($0))년").tag($0) }
                }
                Picker("월", selection: $month) {
                    ForEach(1...12, id: \.self) { Text("\($0)월").tag($0) }
                }
            }
            .pickerStyle(.wheel)
        }
        .background(Color.tsSurface)
    }

    private var selectedDate: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }
}

#Preview {
    PeriodPickerSheet(selection: Date(), onDone: { _ in })
}
