import Foundation

/// GET · PATCH /me 응답 (TeamSpace-backend develop `shared.user_profile`)
/// 소속은 `dept` 로 "Native · {dept}" 를 만들고, 한 줄 소개는 `bio` 예요.
/// 미모티콘 배경색(`avatarBackground`)이 비어 있거나 모르는 값이면 회색이에요.
struct ServerProfileDTO: Decodable {
    let id: Int?
    let name: String
    let dept: String
    let bio: String
    let interests: [String]
    let avatarBackground: AvatarBackground
    /// 프로필 사진 주소 (`/people/{id}/photo?v=…`) — 없으면 빈 값
    let photo: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIntOrString(forKey: .id)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        dept = (try? container.decodeIfPresent(String.self, forKey: .dept)) ?? ""
        bio = (try? container.decodeIfPresent(String.self, forKey: .bio)) ?? ""
        interests = (try? container.decodeIfPresent([String].self, forKey: .interests)) ?? []
        let background = (try? container.decodeIfPresent(String.self, forKey: .avatarBackground)) ?? nil
        avatarBackground = background.flatMap(AvatarBackground.init(rawValue:)) ?? .gray
        photo = (try? container.decodeIfPresent(String.self, forKey: .photo)) ?? nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, dept, bio, interests, avatarBackground, photo
    }

    func toEntity() -> MyProfile {
        let affiliation = dept.isEmpty ? "Native" : "Native · \(dept)"
        return MyProfile(name: name, affiliation: affiliation, intro: bio, interests: interests, avatarBackground: avatarBackground, department: dept, photo: ProfilePhoto(photo))
    }
}

/// PATCH /me 요청 — 사진은 바꿀 때만 보내요.
/// 새 사진은 `data:image/jpeg;base64,…`, 지울 때는 빈 문자열이에요. (서버가 파일로 저장하고 주소로 돌려줘요)
struct ServerProfilePatchRequestDTO: Codable, Equatable {
    let bio: String
    let interests: [String]
    let avatarBackground: String
    let photo: String?

    init(_ update: ProfileUpdate) {
        bio = update.intro
        interests = update.interests
        avatarBackground = update.avatarBackground.rawValue
        switch update.photo {
        case .keep:
            photo = nil
        case let .upload(data, mimeType):
            photo = "data:\(mimeType);base64,\(data.base64EncodedString())"
        case .remove:
            photo = ""
        }
    }
}
