import SwiftUI

/// 카드 안의 `항목명 ······ 값` 행
struct KeyValueRow<Value: View>: View {
    let title: String
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Text(title)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk3)
            Spacer(minLength: Spacing.sm)
            value()
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }
}

/// `KeyValueRow` 의 글자 값 (시스템 글자 크기를 따라 커져요)
struct KeyValueText: View {
    let text: String

    var body: some View {
        Text(text)
            .tsFont(.calloutBold)
            .foregroundStyle(Color.tsInk)
    }
}

extension KeyValueRow where Value == KeyValueText {
    init(title: String, value: String) {
        self.title = title
        self.value = { KeyValueText(text: value) }
    }
}

#Preview {
    VStack(spacing: 0) {
        KeyValueRow(title: "이름", value: "옥물결")
        TSDivider()
        KeyValueRow(title: "요청 상태") {
            StatusBadge(title: "검토 중", tone: .primary)
        }
    }
    .padding()
}
