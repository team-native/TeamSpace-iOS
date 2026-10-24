import SwiftUI

/// 타이포그래피 토큰. 사용: `.tsFont(.title3)`
enum TSFontStyle {
    case display        // 34 Bold — 큰 금액
    case amount         // 30 Bold
    case title1         // 28 Bold
    case title2         // 24 Bold
    case title3         // 22 Bold
    case headline       // 17 Bold
    case subheadline    // 16 Bold
    case body           // 15 Regular
    case bodyBold       // 15 Bold
    case callout        // 14 Regular
    case calloutBold    // 14 Bold
    case footnote       // 13 Regular
    case footnoteMedium // 13 Medium
    case footnoteBold   // 13 Bold
    case caption        // 12 Regular
    case captionMedium  // 12 Medium
    case captionBold    // 12 Bold
    case caption2       // 11 Regular
    case caption2Bold   // 11 Bold
    case micro          // 10 Bold

    var size: CGFloat {
        switch self {
        case .display: return 34
        case .amount: return 30
        case .title1: return 28
        case .title2: return 24
        case .title3: return 22
        case .headline: return 17
        case .subheadline: return 16
        case .body, .bodyBold: return 15
        case .callout, .calloutBold: return 14
        case .footnote, .footnoteMedium, .footnoteBold: return 13
        case .caption, .captionMedium, .captionBold: return 12
        case .caption2, .caption2Bold: return 11
        case .micro: return 10
        }
    }

    var weight: Font.Weight {
        switch self {
        case .body, .callout, .footnote, .caption, .caption2:
            return .regular
        case .footnoteMedium, .captionMedium:
            return .medium
        default:
            return .bold
        }
    }

    var font: Font {
        .system(size: size, weight: weight)
    }
}

extension View {
    func tsFont(_ style: TSFontStyle) -> some View {
        font(style.font)
    }
}

extension Font {
    static func ts(_ style: TSFontStyle) -> Font {
        style.font
    }
}
