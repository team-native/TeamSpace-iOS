import SwiftUI

/// 아이콘(SF Symbol) 크기 토큰. 사용: `.tsIconSize(.sm)`
enum TSIconSize {
    case xxs    // 10 — 체크박스 안 체크
    case xs     // 11
    case sm     // 12 — 안내 문구 옆 아이콘
    case md     // 13
    case mdLarge // 14 — 안내 문구 옆 설정 아이콘
    case base   // 16 — 원형 버튼 안 쉐브론
    case lg     // 17
    case xl     // 20
    case xxl    // 26
    case hero   // 32

    var size: CGFloat {
        switch self {
        case .xxs: return 10
        case .xs: return 11
        case .sm: return 12
        case .md: return 13
        case .mdLarge: return 14
        case .base: return 16
        case .lg: return 17
        case .xl: return 20
        case .xxl: return 26
        case .hero: return 32
        }
    }
}

extension View {
    func tsIconSize(_ size: TSIconSize, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size.size, weight: weight))
    }
}
