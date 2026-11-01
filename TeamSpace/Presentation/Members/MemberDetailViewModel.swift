import Foundation
import Observation

/// 02-4 팀원 상세
@Observable
@MainActor
final class MemberDetailViewModel {
    private(set) var state: ViewState<MemberDetail> = .idle
    var toastMessage: String?

    let memberId: Int
    private let fetchMemberDetailUseCase: FetchMemberDetailUseCase

    init(memberId: Int, fetchMemberDetailUseCase: FetchMemberDetailUseCase) {
        self.memberId = memberId
        self.fetchMemberDetailUseCase = fetchMemberDetailUseCase
    }

    /// 프로필 링크 (앱 안에서 다시 열 수 있는 주소)
    var profileLink: String {
        "teamspace://users/\(memberId)"
    }

    /// "2026년 3월 · 2기"
    func joinedText(_ detail: MemberDetail) -> String {
        "\(TSFormat.yearMonth(detail.member.joinedAt)) · \(detail.generation)기"
    }

    func mailURL(_ detail: MemberDetail) -> URL? {
        URL(string: "mailto:\(detail.email)")
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchMemberDetailUseCase.execute(id: memberId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "memberDetail.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func didCopyLink() {
        toastMessage = "프로필 링크를 복사했어요."
    }
}
