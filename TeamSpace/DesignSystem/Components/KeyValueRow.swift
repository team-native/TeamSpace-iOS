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

extension KeyValueRow where Value == Text {
    init(title: String, value: String) {
        self.title = title
        self.value = {
            Text(value)
                .font(.ts(.calloutBold))
                .foregroundColor(Color.tsInk)
        }
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
