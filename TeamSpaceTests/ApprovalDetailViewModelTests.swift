import XCTest
@testable import TeamSpace

@MainActor
final class ApprovalDetailViewModelTests: XCTestCase {
    /// 같은 Mock 서버를 쓰는 컨테이너 (목록 · 상세가 상태를 공유)
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    // MARK: 05-3 내 결재 상세

    func testMyDetailFromFigma() async throws {
        let viewModel = makeContainer().makeApprovalDetailViewModel(documentId: 1)

        await viewModel.load()

        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertTrue(detail.isMine)
        XCTAssertTrue(detail.canEdit, "검토 중이면 요청 취소 · 수정하기")
        XCTAssertFalse(detail.canDecide)
        XCTAssertEqual(detail.fields.map(\.title), ["비용 유형", "프로젝트", "사용 예정일"])
        XCTAssertEqual(detail.approvers.map(\.name), ["안율", "김민준", "이시우"])
        XCTAssertEqual(detail.attachments.first?.name, "견적서_iPhone.pdf")
        XCTAssertEqual(detail.comments.first?.body, "모델명만 견적서에 추가해 주세요!")
    }

    func testWithdraw() async {
        let viewModel = makeContainer().makeApprovalDetailViewModel(documentId: 1)
        await viewModel.load()

        await viewModel.withdraw()

        XCTAssertTrue(viewModel.didWithdraw)
    }

    // MARK: 05-4 받은 결재 검토 · 05-9 · 05-10

    func testApproveShowsCompletedDialog() async throws {
        let container = makeContainer()
        let viewModel = container.makeApprovalDetailViewModel(documentId: 11)
        await viewModel.load()
        let detail = try XCTUnwrap(viewModel.detail)
        XCTAssertTrue(detail.canDecide)
        XCTAssertEqual(detail.nextApprover?.name, "김민준", "05-9 다음 결재자")
        XCTAssertEqual(viewModel.reviewMeta.hasSuffix("결재선 1/3"), true)

        viewModel.commentDraft = "확인했어요"
        await viewModel.approve()

        XCTAssertEqual(viewModel.dialog, .completed(.approve))
        XCTAssertEqual(viewModel.detail?.item.status, .approved)
        XCTAssertFalse(viewModel.detail?.canDecide ?? true, "처리 후에는 버튼이 사라져요")
        XCTAssertTrue(viewModel.detail?.comments.contains { $0.body == "확인했어요" } ?? false)
    }

    // MARK: 05-8 반려 사유

    func testRejectNeedsReason() async {
        let viewModel = makeContainer().makeApprovalDetailViewModel(documentId: 12)
        await viewModel.load()

        viewModel.rejectReason = "   "
        await viewModel.reject()
        XCTAssertEqual(viewModel.toastMessage, "반려 사유를 입력해 주세요.")
        XCTAssertNil(viewModel.dialog)

        viewModel.rejectReason = "예산 초과"
        await viewModel.reject()
        XCTAssertEqual(viewModel.dialog, .completed(.reject))
        XCTAssertEqual(viewModel.detail?.item.status, .rejected)
    }

    func testCommentIsAdded() async {
        let viewModel = makeContainer().makeApprovalDetailViewModel(documentId: 12)
        await viewModel.load()

        viewModel.commentDraft = "장소 링크도 같이 주세요"
        await viewModel.sendComment()

        XCTAssertEqual(viewModel.commentDraft, "")
        XCTAssertEqual(viewModel.detail?.comments.last?.body, "장소 링크도 같이 주세요")
    }
}
