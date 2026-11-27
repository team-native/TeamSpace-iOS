import Foundation

/// 프로필 미모티콘 배경색
enum AvatarBackground: String, UnknownCaseDecodable, Encodable, Hashable, CaseIterable, Sendable {
    case gray = "GRAY"
    case blue = "BLUE"
    case yellow = "YELLOW"
    case green = "GREEN"
    case pink = "PINK"
    case white = "WHITE"
    case unknown = "UNKNOWN"

    static let unknownCase: AvatarBackground = .unknown
    static let selectable: [AvatarBackground] = [.gray, .blue, .yellow, .green, .pink, .white]

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
    /// 서버 `dept` (예: "NativeOps") — 운영 제안 담당 부서 확인에 써요.
    var department: String = ""
    /// 서버에 올린 프로필 사진 — 없으면 nil
    var photo: ProfilePhoto?
}

/// 07-16 프로필 사진을 어떻게 할지
enum ProfilePhotoChange: Equatable, Sendable {
    /// 그대로 둬요 (PATCH 에 photo 를 안 보내요)
    case keep
    /// 새 사진으로 바꿔요 — `data:image/…;base64,` 로 보내요.
    case upload(data: Data, mimeType: String)
    /// 지워요 — photo 를 빈 문자열로 보내요.
    case remove
}

/// 07-13 저장할 수 있는 항목
struct ProfileUpdate: Equatable, Sendable {
    let intro: String
    let interests: [String]
    let avatarBackground: AvatarBackground
    var photo: ProfilePhotoChange = .keep
}
