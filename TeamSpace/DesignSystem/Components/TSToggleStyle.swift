import SwiftUI

/// Figma `toggle` — 48×28 캡슐 스위치 (켜짐: primary / 꺼짐: line)
struct TSToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Spacing.md) {
                configuration.label
                Spacer(minLength: 0)
                Capsule()
                    .fill(configuration.isOn ? Color.tsPrimary : Color.tsLine)
                    .frame(width: 48, height: 28)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Color.tsOnPrimary)
                            .frame(width: 22, height: 22)
                            .tsShadow(.card)
                            .padding(Spacing.compact)
                    }
                    .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension ToggleStyle where Self == TSToggleStyle {
    static var ts: TSToggleStyle { TSToggleStyle() }
}

#Preview {
    VStack {
        Toggle("결재 · 내 할 일", isOn: .constant(true))
        Toggle("전체 공지", isOn: .constant(false))
    }
    .toggleStyle(.ts)
    .padding()
}
