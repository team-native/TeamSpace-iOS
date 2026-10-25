import Foundation

/// GET · PATCH /workspace/profile 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-13 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct MyProfileDTO: Codable {
    let name: String
    let affiliation: String
    let intro: String
    let interests: [String]
    let avatarBackground: AvatarBackground

    func toEntity() -> MyProfile {
        MyProfile(name: name, affiliation: affiliation, intro: intro, interests: interests, avatarBackground: avatarBackground)
    }
}

/// PATCH /workspace/profile 요청 바디
struct ProfileUpdateRequestDTO: Codable {
    let intro: String
    let interests: [String]
    let avatarBackground: String

    init(_ update: ProfileUpdate) {
        intro = update.intro
        interests = update.interests
        avatarBackground = update.avatarBackground.rawValue
    }
}
