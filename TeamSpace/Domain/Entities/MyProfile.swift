import Foundation

/// 프로필 미모티콘 배경색
enum AvatarBackground: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case gray = "GRAY"
    case blue = "BLUE"
    case yellow = "YELLOW"
    case green = "GREEN"
    case pink = "PINK"
    case unknown = "UNKNOWN"

    static let unknownCase: AvatarBackground = .unknown
    static let selectable: [AvatarBackground] = [.gray, .blue, .yellow, .green, .pink]

    /// 배경색 바꾸기 — 다음 색으로
    var next: AvatarBackground {
        let colors = Self.selectable
        guard let index = colors.firstIndex(of: self) else { return .gray }
        return colors[(index + 1) % colors.count]
    }
}

/// 07-13 내 프로필
struct MyProfile: Equatable, Sendable {
    let name: String
    /// 예) "Native · Design" (운영진만 바꿀 수 있어요)
    let affiliation: String
    var intro: String
    var interests: [String]
    var avatarBackground: AvatarBackground
}

/// 07-13 저장할 수 있는 항목
struct ProfileUpdate: Equatable, Sendable {
    let intro: String
    let interests: [String]
    let avatarBackground: AvatarBackground
}
