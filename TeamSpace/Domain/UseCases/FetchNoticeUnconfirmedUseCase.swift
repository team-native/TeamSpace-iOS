import Foundation

/// 공지 미확인자 — Admin 만 볼 수 있어요. 이름순으로 정렬해요.
struct FetchNoticeUnconfirmedUseCase {
    private let noticeRepository: NoticeRepository

    init(noticeRepository: NoticeRepository) {
        self.noticeRepository = noticeRepository
    }

    func execute(noticeId: Int, user: AuthUser) async throws -> [NoticeUnconfirmedMember] {
        guard user.can(.viewNoticeReceipts) else { throw AppError.forbidden("확인 현황은 관리자만 볼 수 있어요.") }
        return try await noticeRepository.fetchUnconfirmed(noticeId: noticeId)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
