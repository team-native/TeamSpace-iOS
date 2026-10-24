import SwiftUI

/// Figma `checkbox` — 파란 둥근 사각 체크박스
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: Radius.xs, style: .continuous)
                    .fill(configuration.isOn ? Color.tsPrimary : Color.tsSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.xs, style: .continuous)
                            .stroke(configuration.isOn ? Color.tsPrimary : Color.tsLine, lineWidth: 1)
                    }
                    .overlay {
                        if configuration.isOn {
                            TSIcon.check.image
                                .tsIconSize(.xxs, weight: .bold)
                                .foregroundStyle(Color.tsOnPrimary)
                        }
                    }
                    .frame(width: 18, height: 18)
                configuration.label
                    .tsFont(.footnoteMedium)
                    .foregroundStyle(Color.tsInk2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "선택됨" : "선택 안 됨")
    }
}

private struct CheckboxPreview: View {
    @State private var isOn = true

    var body: some View {
        Toggle("로그인 상태 유지", isOn: $isOn)
            .toggleStyle(CheckboxToggleStyle())
            .padding()
    }
}

#Preview {
    CheckboxPreview()
}
