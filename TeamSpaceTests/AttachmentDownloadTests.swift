import XCTest
@testable import TeamSpace

/// 첨부 파일 내려받기 (GET /uploads/{id}) — 결재 · 공지 상세
@MainActor
final class AttachmentDownloadTests: XCTestCase {
    private func makeClient() -> APIClient {
        APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: InMemoryTokenStorage()
        )
    }

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(baseURL: MockTransport.baseURL, transport: MockTransport(latencyNanoseconds: 0), tokenStorage: tokenStorage)
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testApprovalAttachmentDownloadsAndOpens() async throws {
        let detailViewModel = makeContainer().makeApprovalDetailViewModel(documentId: 1)
        await detailViewModel.load()
        let file = try XCTUnwrap(detailViewModel.detail?.attachments.first)
        XCTAssertEqual(file.name, "견적서_iPhone.pdf")
        XCTAssertEqual(file.fileId, "9")
        XCTAssertTrue(file.canDownload)

        let downloader = try XCTUnwrap(detailViewModel.attachmentDownloader)
        await downloader.open(file)
        XCTAssertNil(downloader.errorMessage)
        let url = try XCTUnwrap(downloader.previewURL)
        XCTAssertEqual(url.lastPathComponent, "견적서_iPhone.pdf")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "%PDF-1.4 mock quote")
        XCTAssertNil(downloader.downloadingId)
    }

    func testNoticeShowsAttachmentsAndDownloads() async throws {
        let viewModel = makeContainer().makeNoticeDetailViewModel(noticeId: 41)
        await viewModel.load()
        let file = try XCTUnwrap(viewModel.detail?.attachments.first)
        XCTAssertEqual(file.name, "10월_정산표.csv")
        XCTAssertEqual(file.sizeText, FileAttachment.sizeText(2_048))

        let downloader = try XCTUnwrap(viewModel.attachmentDownloader)
        await downloader.open(file)
        let url = try XCTUnwrap(downloader.previewURL)
        XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).hasPrefix("프로젝트,금액"))

        let other = makeContainer().makeNoticeDetailViewModel(noticeId: 42)
        await other.load()
        XCTAssertEqual(other.detail?.attachments, [], "첨부가 없는 공지")
    }

    func testMissingFileAndNoId() async {
        let useCase = DownloadAttachmentUseCase(uploadRepository: UploadRepositoryImpl(client: makeClient()))
        do {
            _ = try await useCase.execute(FileAttachment(name: "옛 첨부.pdf", sizeText: "1KB"))
            XCTFail("id 가 없으면 못 받아요")
        } catch {
            XCTAssertEqual(error.userMessage, "내려받을 수 없는 파일이에요.")
        }

        let downloader = AttachmentDownloadViewModel(downloadAttachmentUseCase: useCase)
        await downloader.open(FileAttachment(name: "없는 파일.pdf", sizeText: "1KB", fileId: "999"))
        XCTAssertNil(downloader.previewURL)
        XCTAssertEqual(downloader.errorMessage, "파일을 찾을 수 없습니다.")
    }

    func testUploadIdParsingAndSafeName() {
        XCTAssertEqual(FileAttachment.uploadId(id: "12", url: nil), "12")
        XCTAssertEqual(FileAttachment.uploadId(id: nil, url: "/uploads/34?download=1"), "34")
        XCTAssertNil(FileAttachment.uploadId(id: nil, url: "https://example.com/a.pdf"))
        XCTAssertEqual(UploadRepositoryImpl.safeName("../보고서/최종.pdf"), "file.._보고서_최종.pdf")
        XCTAssertEqual(UploadRepositoryImpl.safeName("  "), "file")

    }

    func testUploadedFileCanBeDownloadedAgain() async throws {
        let client = makeClient()
        let uploaded = try await client.request(
            Endpoint(method: .post, path: "uploads", file: MultipartFile(filename: "photo.jpg", mimeType: "image/jpeg", data: Data([0xFF, 0xD8, 0xFF]))),
            as: ServerIdResponseDTO.self
        )
        let url = try await UploadRepositoryImpl(client: client).download(id: uploaded.id, filename: "photo.jpg")
        XCTAssertEqual(try Data(contentsOf: url), Data([0xFF, 0xD8, 0xFF]))
    }
}
