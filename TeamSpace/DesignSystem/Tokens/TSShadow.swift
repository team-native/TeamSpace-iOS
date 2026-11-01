import SwiftUI

enum TSShadow {
    case none
    case card
    case raised
    case primaryGlow

    fileprivate var color: Color {
        switch self {
        case .none: return .clear
        case .card: return Color.tsScrim.opacity(0.04)
        case .raised: return Color.tsScrim.opacity(0.10)
        case .primaryGlow: return Color.tsPrimary.opacity(0.22)
        }
    }

    fileprivate var radius: CGFloat {
        switch self {
        case .none: return 0
        case .card: return 12
        case .raised: return 20
        case .primaryGlow: return 14
        }
    }

    fileprivate var y: CGFloat {
        switch self {
        case .none: return 0
        case .card: return 4
        case .raised: return 6
        case .primaryGlow: return 6
        }
    }
}

extension View {
    func tsShadow(_ shadow: TSShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
