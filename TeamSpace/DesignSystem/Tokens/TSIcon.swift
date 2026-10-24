import SwiftUI

/// Figma 아이콘 → SF Symbols 매핑
enum TSIcon: String {
    case mail = "envelope"
    case eye = "eye"
    case eyeSlash = "eye.slash"
    case check = "checkmark"
    case info = "exclamationmark.circle"
    case chevronLeft = "chevron.left"
    case chevronDown = "chevron.down"
    case shield = "checkmark.shield"
    case clock = "clock"

    var image: Image {
        Image(systemName: rawValue)
    }
}
