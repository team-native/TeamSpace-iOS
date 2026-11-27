import Foundation

/// 07-13 프로필 저장 — 한 줄 소개 40자, 관심사 5개(각 10자)까지, 사진 5MB 까지
struct UpdateProfileUseCase {
    static let introLimit = 40
    static let interestLimit = 5
    static let interestLength = 10
    /// 서버 `MAX_AVATAR_BYTES`
    static let photoByteLimit = 5 * 1024 * 1024

    private let workspaceRepository: WorkspaceRepository

    init(workspaceRepository: WorkspaceRepository) {
        self.workspaceRepository = workspaceRepository
    }

    /// 관심사 하나를 다듬어요. ("#UI" · " UI " → "UI") 쓸 수 없으면 안내 문구를 던져요.
    static func normalizedInterest(_ raw: String, existing: [String]) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw AppError.invalidInput("관심사를 입력해 주세요.") }
        guard trimmed.count <= interestLength else { throw AppError.invalidInput("관심사는 \(interestLength)자까지 쓸 수 있어요.") }
        guard !existing.contains(trimmed) else { throw AppError.invalidInput("이미 추가한 관심사예요.") }
        guard existing.count < interestLimit else { throw AppError.invalidInput("관심사는 \(interestLimit)개까지 추가할 수 있어요.") }
        return trimmed
    }

    func execute(_ update: ProfileUpdate) async throws -> MyProfile {
        let intro = update.intro.trimmingCharacters(in: .whitespacesAndNewlines)
        guard intro.count <= Self.introLimit else {
            throw AppError.invalidInput("한 줄 소개는 \(Self.introLimit)자까지 쓸 수 있어요.")
        }
        guard update.interests.count <= Self.interestLimit else {
            throw AppError.invalidInput("관심사는 \(Self.interestLimit)개까지 추가할 수 있어요.")
        }
        if case let .upload(data, _) = update.photo {
            guard !data.isEmpty else { throw AppError.invalidInput("사진을 불러오지 못했어요. 다른 사진을 골라 주세요.") }
            guard data.count <= Self.photoByteLimit else { throw AppError.invalidInput("프로필 사진은 5MB 이하만 올릴 수 있어요.") }
        }
        return try await workspaceRepository.updateProfile(
            ProfileUpdate(intro: intro, interests: update.interests, avatarBackground: update.avatarBackground, photo: update.photo)
        )
    }
}
