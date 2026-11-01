import SwiftUI

/// 사용: `.buttonStyle(.tsPrimary)` / `.buttonStyle(.tsSecondary)`
struct TSButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case soft
    }

    enum Size {
        case large   // 56
        case medium  // 52
        case small   // 38

        var height: CGFloat {
            switch self {
            case .large: return 56
            case .medium: return 52
            case .small: return 38
            }
        }

        var radius: CGFloat {
            switch self {
            case .large: return Radius.xl
            case .medium: return Radius.lg
            case .small: return Radius.md
            }
        }

        var font: TSFontStyle {
            switch self {
            case .large: return .headline
            case .medium: return .bodyBold
            case .small: return .footnoteBold
            }
        }
    }

    let kind: Kind
    var size: Size = .medium
    var isFullWidth: Bool = true

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tsFont(size.font)
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.lg)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(background, in: RoundedRectangle(cornerRadius: size.radius, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .modifier(PrimaryGlow(isActive: kind == .primary && size == .large && isEnabled))
    }

    private var foreground: Color {
        switch kind {
        case .primary: return .tsOnPrimary
        case .secondary: return .tsInk2
        case .soft: return .tsPrimary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return .tsPrimary
        case .secondary: return .tsSurface2
        case .soft: return .tsPrimarySoft
        }
    }
}

private struct PrimaryGlow: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.tsShadow(.primaryGlow)
        } else {
            content
        }
    }
}

extension ButtonStyle where Self == TSButtonStyle {
    static var tsPrimary: TSButtonStyle { TSButtonStyle(kind: .primary) }
    static var tsPrimaryLarge: TSButtonStyle { TSButtonStyle(kind: .primary, size: .large) }
    static var tsSecondary: TSButtonStyle { TSButtonStyle(kind: .secondary) }

    static func ts(_ kind: TSButtonStyle.Kind, size: TSButtonStyle.Size, fullWidth: Bool = true) -> TSButtonStyle {
        TSButtonStyle(kind: kind, size: size, isFullWidth: fullWidth)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        Button("로그인") {}.buttonStyle(.tsPrimaryLarge)
        Button("알림 허용하기") {}.buttonStyle(.tsPrimary)
        Button("나중에") {}.buttonStyle(.tsSecondary)
        Button("바로 검토") {}.buttonStyle(.ts(.primary, size: .small, fullWidth: false))
    }
    .padding()
}
