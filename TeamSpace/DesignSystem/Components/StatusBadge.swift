import SwiftUI

/// 상태 표시는 이 공용 컴포넌트만 사용합니다. (색상 + 아이콘 + 텍스트)
/// 새 상태 enum 은 `BadgeRepresentable` 을 채택해서 연결하세요.
enum BadgeTone {
    case primary
    case primaryFilled
    case positive
    case negative
    case warning
    case violet
    case amber
    case neutral

    var foreground: Color {
        switch self {
        case .primary: return .tsPrimary
        case .primaryFilled: return .tsOnPrimary
        case .positive: return .tsPositive
        case .negative: return .tsNegative
        case .warning: return .tsApricot
        case .violet: return .tsViolet
        case .amber: return .tsAmber
        case .neutral: return .tsInk2
        }
    }

    var background: Color {
        switch self {
        case .primary: return .tsPrimarySoft
        case .primaryFilled: return .tsPrimary
        case .positive: return .tsPositiveSoft
        case .negative: return .tsNegativeSoft
        case .warning: return .tsApricotSoft
        case .violet: return .tsVioletSoft
        case .amber: return .tsAmberSoft
        case .neutral: return .tsSurface2
        }
    }
}

protocol BadgeRepresentable {
    var badgeTitle: String { get }
    var badgeTone: BadgeTone { get }
    var badgeIcon: TSIcon? { get }
}

extension BadgeRepresentable {
    var badgeIcon: TSIcon? { nil }
}

struct StatusBadge: View {
    enum Size {
        case small
        case regular

        var font: TSFontStyle {
            switch self {
            case .small: return .micro
            case .regular: return .caption2Bold
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return Spacing.xxs
            }
        }
    }

    let title: String
    let tone: BadgeTone
    var icon: TSIcon?
    var size: Size = .regular

    init(title: String, tone: BadgeTone, icon: TSIcon? = nil, size: Size = .regular) {
        self.title = title
        self.tone = tone
        self.icon = icon
        self.size = size
    }

    init(status: BadgeRepresentable, size: Size = .regular) {
        self.init(title: status.badgeTitle, tone: status.badgeTone, icon: status.badgeIcon, size: size)
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let icon {
                icon.image.tsIconSize(.xxs, weight: .bold)
            }
            Text(title)
                .tsFont(size.font)
                .lineLimit(1)
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, Spacing.sm + 1)
        .padding(.vertical, size.verticalPadding)
        .background(tone.background, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        StatusBadge(title: "검토 중", tone: .primary)
        StatusBadge(title: "수금 완료", tone: .positive, size: .small)
        StatusBadge(title: "수금 예정", tone: .warning, size: .small)
        StatusBadge(title: "기기 알림 꺼짐", tone: .negative)
    }
    .padding()
}
