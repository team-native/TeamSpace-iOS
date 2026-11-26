import XCTest
@testable import TeamSpace

/// 공지 · 일정 삭제 (Admin) — DELETE /admin/notices/{id} · /admin/events/{id}
@MainActor
final class NoticeScheduleDeleteTests: XCTestCase {
    private let admin = AuthUser(id: 1, name: "이시우", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "양지우", roles: [.leader])
    private let member = AuthUser(id: 3, name: "옥물결", roles: [.member])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testAdminDeletesNotice() async {
        let container = makeContainer()
        let viewModel = container.makeNoticeDetailViewModel(noticeId: 43, user: admin)
        await viewModel.load()
        XCTAssertTrue(viewModel.canDelete)
        XCTAssertTrue(viewModel.canEdit, "더보기에 수정하기도 있어요")

        await viewModel.delete()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isDeleted)

        let list = container.makeNoticeListViewModel(user: admin)
        await list.load()
        XCTAssertFalse(list.notices.contains { $0.id == 43 }, "목록에서 빠져요")

        let gone = container.makeNoticeDetailViewModel(noticeId: 43, user: admin)
        await gone.load()
        XCTAssertNil(gone.detail, "지운 공지는 다시 열 수 없어요")
    }

    func testOnlyAdminCanDeleteNotice() async {
        let container = makeContainer()
        let asLeader = container.makeNoticeDetailViewModel(noticeId: 43, user: leader)
        await asLeader.load()
        XCTAssertTrue(asLeader.canEdit, "Leader 는 고칠 수만 있어요")
        XCTAssertFalse(asLeader.canDelete)

        let asMember = container.makeNoticeDetailViewModel(noticeId: 43, user: member)
        await asMember.load()
        XCTAssertFalse(asMember.canDelete)

        do {
            try await DeleteNoticeUseCase(noticeRepository: NoticeRepositoryImpl(client: APIClient(
                baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: InMemoryTokenStorage()
            ))).execute(noticeId: 43, user: leader)
            XCTFail("Admin 만 지울 수 있어요")
        } catch AppError.forbidden {
        } catch {
            XCTFail("\(error)")
        }
    }

    func testAdminDeletesSchedule() async {
        let container = makeContainer()
        let viewModel = container.makeScheduleDetailViewModel(scheduleId: 2, user: admin)
        await viewModel.load()
        XCTAssertTrue(viewModel.canDelete)

        await viewModel.delete()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isDeleted)

        let gone = container.makeScheduleDetailViewModel(scheduleId: 2, user: admin)
        await gone.load()
        XCTAssertNil(gone.detail, "지운 일정은 다시 열 수 없어요")
    }

    func testMemberCannotDeleteSchedule() async {
        let viewModel = makeContainer().makeScheduleDetailViewModel(scheduleId: 2, user: member)
        await viewModel.load()
        XCTAssertFalse(viewModel.canDelete)
        XCTAssertTrue(admin.can(.deleteNotices))
        XCTAssertFalse(leader.can(.deleteNotices))
    }
}
