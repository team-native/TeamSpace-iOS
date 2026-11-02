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
        XCTAssertFalse(detail.canEdit, "검토 중이면 서버가 수정을 막아요")
        XCTAssertTrue(detail.canWithdraw, "검토 중이면 요청 취소만")
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
        await viewModel.load()
        XCTAssertEqual(viewModel.detail?.item.status, .cancelled, "서버는 요청 취소를 '취소' 상태로 둬요")
        XCTAssertFalse(viewModel.detail?.canEdit ?? true)
    }

    func testServerApprovalDecoding() throws {
        let json = Data(#"""
        {"id":"41","kind":"인력 지원","type":"iOS 1명","title":"인력 요청","amount":"2026.11 ~ 2026.12","amountValue":0,
         "status":"검토 중","project":"Book-on","period":"2026.11 ~ 2026.12","reason":"QA","author":"이시우","authorId":"7",
         "date":"2026-11-01T09:00:00.123456+09:00",
         "line":[{"who":"이시우","userId":7,"role":"기안","state":"done","at":"2026-11-01T09:00:00+09:00"},
                 {"who":"홍길동","userId":1,"role":"검토","state":"done","at":"2026-11-01T10:12:00+09:00"},
                 {"who":"김민준","userId":2,"role":"승인","state":"now","at":"검토 중"}],
         "files":[{"id":"9","url":"/uploads/9","filename":"a.pdf","size":2048,"contentType":"application/pdf"}],
         "comments":[{"id":"ab12","who":"김민준","text":"확인할게요","createdAt":"2026-11-01T11:00:00+09:00"}],
         "received":false}
        """#.utf8)
        let record = try JSONCoder.makeDecoder().decode(ServerApprovalDTO.self, from: json)
        let mine = record.toDetail(viewerId: 7)
        let approver = record.toDetail(viewerId: 2)

        XCTAssertEqual(mine.item.kind, .staffing)
        XCTAssertNil(mine.item.amount, "인력 지원은 금액이 없어요")
        XCTAssertEqual(mine.item.summary, "iOS 1명 · 2026.11 ~ 2026.12")
        XCTAssertEqual(mine.item.requesterText, "이시우", "서버가 부서를 주지 않으면 이름만")
        XCTAssertEqual(mine.approvers.map(\.name), ["홍길동", "김민준"], "기안 단계는 결재선에서 빼요")
        XCTAssertEqual(mine.approvers.map(\.status), [.approved, .reviewing])
        XCTAssertEqual(mine.fields.map(\.title), ["프로젝트", "필요 인원", "투입 기간"])
        XCTAssertEqual(mine.attachments.first?.name, "a.pdf")
        XCTAssertEqual(mine.comments.first?.body, "확인할게요")
        XCTAssertTrue(mine.isMine)
        XCTAssertNil(mine.myApprovalId)
        XCTAssertFalse(approver.isMine)
        XCTAssertTrue(approver.canDecide, "지금(now) 내 차례면 승인 · 반려")
        XCTAssertEqual(ApprovalStatus(serverValue: "취소"), .cancelled)
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
        XCTAssertEqual(viewModel.detail?.item.status, .reviewing, "다음 결재자(김민준) 차례로 넘어가요")
        XCTAssertEqual(viewModel.detail?.approvers.map(\.status), [.approved, .reviewing, .waiting])
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
