import SwiftUI

/// 05-6b 사용 예정일 (iOS Date Picker)
struct UseDatePickerSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.md) {
            DatePicker("사용 예정일", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .tint(Color.tsPrimary)
                .environment(\.locale, Locale(identifier: "ko_KR"))
            Button("완료") { dismiss() }
                .buttonStyle(.tsPrimary)
        }
        .padding(Spacing.xl)
        .background(Color.tsSurface)
    }
}

/// 05-6 투입 기간 — 시작 달 · 종료 달
struct MonthRangePickerSheet: View {
    let onDone: (Date, Date) -> Void

    @State private var start: Date
    @State private var end: Date
    @Environment(\.dismiss) private var dismiss
    private let months: [Date]

    init(start: Date, end: Date, onDone: @escaping (Date, Date) -> Void) {
        self.onDone = onDone
        let calendar = Calendar.current
        let first = calendar.startOfMonth(for: Date())
        let months = (0..<18).compactMap { calendar.date(byAdding: .month, value: $0, to: first) }
        self.months = months
        _start = State(initialValue: months.first { $0 == calendar.startOfMonth(for: start) } ?? first)
        _end = State(initialValue: months.first { $0 == calendar.startOfMonth(for: end) } ?? first)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") { dismiss() }
                    .tsFont(.body)
                    .foregroundStyle(Color.tsInk2)
                Spacer()
                Text("투입 기간").tsFont(.bodyBold).foregroundStyle(Color.tsInk)
                Spacer()
                Button("완료") { onDone(start, end) }
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            .padding(.horizontal, Spacing.xl)
            .frame(height: 48)
            HStack(spacing: 0) {
                monthPicker("시작", selection: $start)
                Text("~").tsFont(.bodyBold).foregroundStyle(Color.tsInk3)
                monthPicker("종료", selection: $end)
            }
        }
        .background(Color.tsSurface)
    }

    private func monthPicker(_ title: String, selection: Binding<Date>) -> some View {
        Picker(title, selection: selection) {
            ForEach(months, id: \.self) { month in
                Text(TSFormat.yearMonth(month)).tag(month)
            }
        }
        .pickerStyle(.wheel)
    }
}

/// 05-7 결재 제출 완료
struct SubmitCompletedDialog: View {
    let firstApproverName: String
    let onShowDocument: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        TSDialog(onDismiss: onConfirm) {
            VStack(spacing: 0) {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.tsOnPrimary)
                        .frame(width: 68, height: 68)
                        .background(Circle().fill(Color.tsPrimary))
                    VStack(spacing: Spacing.xs) {
                        Text("결재를 올렸어요")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.tsInk)
                        Text("\(firstApproverName) 님이 검토를 시작하면\n알림으로 알려드려요.")
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk3)
                            .multilineTextAlignment(.center)
                    }
                    HStack(spacing: Spacing.md) {
                        AvatarView(size: 36)
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(firstApproverName).tsFont(.calloutBold).foregroundStyle(Color.tsInk)
                            Text("결재 담당자").tsFont(.caption).foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                        StatusBadge(title: "검토 대기중", tone: .primary)
                    }
                    .padding(Spacing.md + Spacing.xxxs)
                    .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.tsSurface2))
                }
                .padding(Spacing.xxl)
                TSDivider()
                HStack(spacing: 0) {
                    Button("내 결재 보기", action: onShowDocument)
                        .tsFont(.body)
                        .foregroundStyle(Color.tsInk3)
                        .frame(maxWidth: .infinity, minHeight: 56)
                    Rectangle().fill(Color.tsLine).frame(width: 1, height: 56)
                    Button("확인", action: onConfirm)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsPrimary)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("05-7") {
    SubmitCompletedDialog(firstApproverName: "안율", onShowDocument: {}, onConfirm: {})
}
