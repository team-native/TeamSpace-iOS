import SwiftUI

/// Figma 아이콘 → SF Symbols 매핑
enum TSIcon: String {
    case mail = "envelope"
    case eye = "eye"
    case eyeSlash = "eye.slash"
    case check = "checkmark"
    case info = "exclamationmark.circle"

    var image: Image {
        Image(systemName: rawValue)
    }
}
