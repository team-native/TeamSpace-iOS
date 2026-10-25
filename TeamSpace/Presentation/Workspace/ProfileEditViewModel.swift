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
    /// 사진 보관함 · 스티커로 고른 이미지 (업로드 API 가 정해지면 함께 저장)
    private(set) var avatarImageData: Data?

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
        guard let data else {
            errorMessage = "이미지를 불러오지 못했어요. 다른 이미지를 골라 주세요."
            return
        }
        avatarImageData = data
    }

    func changeBackground() {
        avatarBackground = avatarBackground.next
    }

    func resetAvatar() {
        avatarImageData = nil
        avatarBackground = .gray
    }

    // MARK: 저장

    func save() async {
        guard hasChanges, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await updateProfileUseCase.execute(
                ProfileUpdate(intro: intro, interests: interests, avatarBackground: avatarBackground)
            )
            state = .loaded(saved)
            intro = saved.intro
            didSave = true
        } catch {
            AppLog.record(error, context: "workspace.profile.save")
            errorMessage = error.userMessage
        }
    }
}
