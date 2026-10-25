import Foundation

/// Mock 프로필 — Figma 07-13 예시. 저장한 내용을 메모리에 기억해요.
final class MockProfileStore: @unchecked Sendable {
    private let lock = NSLock()
    private var profile = MyProfileDTO(
        name: "옥물결",
        affiliation: "Native · Design",
        intro: "뾰로롱",
        interests: ["UI", "타이포"],
        avatarBackground: .gray
    )

    func json() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(profile)
    }

    func update(_ request: ProfileUpdateRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        profile = MyProfileDTO(
            name: profile.name,
            affiliation: profile.affiliation,
            intro: request.intro,
            interests: request.interests,
            avatarBackground: AvatarBackground(rawValue: request.avatarBackground) ?? .gray
        )
        return envelope(profile)
    }

    private func envelope(_ value: MyProfileDTO) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
