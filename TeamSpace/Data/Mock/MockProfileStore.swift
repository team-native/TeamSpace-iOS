import Foundation

/// Mock 프로필 — 서버 develop `GET · PATCH /me` 형식(Figma 07-13 예시). 저장한 내용을 메모리에 기억해요.
/// 배경색(`avatarBackground`)은 서버에 아직 없지만, 백엔드에 요청한 대로 저장하고 돌려줘요.
final class MockProfileStore: @unchecked Sendable {
    private let lock = NSLock()
    private var fields: [String: Any] = [
        "id": "1",
        "name": "옥물결",
        "email": "member@gsm.hs.kr",
        "dept": "Design",
        "role": "",
        "major": "",
        "cohort": "",
        "github": "",
        "photo": "",
        "joined": "2026-03-02T00:00:00+00:00",
        "bio": "뾰로롱",
        "interests": ["UI", "타이포"],
        "projects": [] as [Any],
        "isNew": false,
        "lead": false,
        "roles": ["Member"],
        "avatarBackground": "GRAY"
    ]

    func json() -> String {
        lock.lock()
        defer { lock.unlock() }
        return encoded()
    }

    func update(_ request: ServerProfilePatchRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        fields["bio"] = request.bio
        fields["interests"] = request.interests
        fields["avatarBackground"] = request.avatarBackground
        return encoded()
    }

    private func encoded() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}
