import Foundation
import Observation

/// 07-13 프로필 편집 · 07-16 미모티콘 바꾸기
@Observable
@MainActor
final class ProfileEditViewModel {
    private(set) var state: ViewState<MyProfile> = .idle
    var intro = ""
    private(set) var interests: [String] = []
    private(set) var avatarBackground: AvatarBackground = .gray
    /// 사진 보관함 · 스티커로 새로 고른 이미지 (줄인 뒤) — 저장할 때 올려요.
    private(set) var avatarImageData: Data?
    private var avatarMimeType = "image/jpeg"
    /// "기본 이미지로 변경" 을 눌러 서버 사진을 지울 거예요.
    private(set) var isPhotoRemoved = false

    var isAvatarMenuPresented = false
    var isPhotoPickerPresented = false
    var isInterestAlertPresented = false
    var newInterest = ""
    private(set) var isSaving = false
    /// 저장이 끝나면 true → 화면을 닫아요.
    private(set) var didSave = false
    var errorMessage: String?

    private let fetchProfileUseCase: FetchProfileUseCase
    private let updateProfileUseCase: UpdateProfileUseCase

    init(fetchProfileUseCase: FetchProfileUseCase, updateProfileUseCase: UpdateProfileUseCase) {
        self.fetchProfileUseCase = fetchProfileUseCase
        self.updateProfileUseCase = updateProfileUseCase
    }

    var profile: MyProfile? { state.value }

    /// 바뀐 게 있을 때만 저장할 수 있어요.
    var hasChanges: Bool {
        guard let profile else { return false }
        return intro != profile.intro
            || interests != profile.interests
            || avatarBackground != profile.avatarBackground
            || avatarImageData != nil
            || (isPhotoRemoved && profile.photo != nil)
    }

    /// 지금 보여줄 서버 사진 — 새로 골랐거나 지우기로 했으면 nil
    var currentPhoto: ProfilePhoto? {
        guard avatarImageData == nil, !isPhotoRemoved else { return nil }
        return profile?.photo
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let profile = try await fetchProfileUseCase.execute()
            state = .loaded(profile)
            intro = profile.intro
            interests = profile.interests
            avatarBackground = profile.avatarBackground
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.profile.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    // MARK: 관심사

    func addInterest() {
        do {
            interests.append(try UpdateProfileUseCase.normalizedInterest(newInterest, existing: interests))
            newInterest = ""
        } catch {
            errorMessage = error.userMessage
        }
    }

    func removeInterest(_ interest: String) {
        interests.removeAll { $0 == interest }
    }

    // MARK: 07-16 미모티콘 바꾸기

    func setAvatarImage(_ data: Data?) {
        guard let data, let encoded = ProfilePhotoEncoder.encode(data) else {
            errorMessage = "이미지를 불러오지 못했어요. 다른 이미지를 골라 주세요."
            return
        }
        avatarImageData = encoded.data
        avatarMimeType = encoded.mimeType
        isPhotoRemoved = false
    }

    func changeBackground() {
        avatarBackground = avatarBackground.next
    }

    /// 고른 사진과 서버 사진을 모두 지우고 회색 배경으로 돌려요. (저장해야 서버에서도 지워져요)
    func resetAvatar() {
        avatarImageData = nil
        isPhotoRemoved = profile?.photo != nil
        avatarBackground = .gray
    }

    private var photoChange: ProfilePhotoChange {
        if let avatarImageData { return .upload(data: avatarImageData, mimeType: avatarMimeType) }
        return isPhotoRemoved ? .remove : .keep
    }

    // MARK: 저장

    func save() async {
        guard hasChanges, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await updateProfileUseCase.execute(
                ProfileUpdate(intro: intro, interests: interests, avatarBackground: avatarBackground, photo: photoChange)
            )
            state = .loaded(saved)
            intro = saved.intro
            avatarImageData = nil
            isPhotoRemoved = false
            didSave = true
        } catch {
            AppLog.record(error, context: "workspace.profile.save")
            errorMessage = error.userMessage
        }
    }
}
