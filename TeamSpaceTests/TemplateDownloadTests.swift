import XCTest
@testable import TeamSpace

@MainActor
final class TemplateDownloadTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let storage = InMemoryTokenStorage()
        return DIContainer(
            apiClient: APIClient(
                baseURL: MockTransport.baseURL,
                transport: MockTransport(latencyNanoseconds: 0),
                tokenStorage: storage
            ),
            tokenStorage: storage
        )
    }

    private func decode(_ json: String) throws -> ServerDocDTO {
        try JSONDecoder().decode(ServerDocDTO.self, from: Data(json.utf8))
    }

    func testTemplateWithFileShowsDownloadableFile() async throws {
        let detail = makeContainer().makeTemplateDetailViewModel(templateId: "budget-request")
        await detail.load()
        let file = try XCTUnwrap(detail.state.value?.file)
        XCTAssertEqual(file.fileId, "31")
        XCTAssertEqual(file.name, "예산_품의서_양식.csv")
        XCTAssertTrue(file.canDownload)
        XCTAssertNotNil(detail.attachmentDownloader)
    }

    func testTemplateWithoutFileHasNoFile() async throws {
        let detail = makeContainer().makeTemplateDetailViewModel(templateId: "staffing-request")
        await detail.load()
        XCTAssertNotNil(detail.state.value)
        XCTAssertNil(detail.state.value?.file)
    }

    func testDownloadsTemplateFileForPreview() async throws {
        let detail = makeContainer().makeTemplateDetailViewModel(templateId: "budget-request")
        await detail.load()
        let file = try XCTUnwrap(detail.state.value?.file)
        let downloader = try XCTUnwrap(detail.attachmentDownloader)

        await downloader.open(file)

        let url = try XCTUnwrap(downloader.previewURL)
        XCTAssertEqual(url.lastPathComponent, "예산_품의서_양식.csv")
        XCTAssertEqual(String(decoding: try Data(contentsOf: url), as: UTF8.self), "항목,금액,사유\n,,\n")
        XCTAssertNil(downloader.errorMessage)
    }

    func testReadsFileFromDownloadUrlAndFallsBackToTitle() throws {
        let doc = try decode("""
        {"slug":"t","type":"TEMPLATE","title":"구매 요청서","downloadUrl":"/uploads/77","size":2048}
        """)
        let file = try XCTUnwrap(doc.toTemplate().file)
        XCTAssertEqual(file.fileId, "77")
        XCTAssertEqual(file.name, "구매 요청서")
        XCTAssertEqual(file.sizeText, FileAttachment.sizeText(2048))
    }

    func testNumericFileIdAndMissingFile() throws {
        let numeric = try decode("""
        {"slug":"t","type":"TEMPLATE","title":"양식","fileId":5,"filename":"양식.docx"}
        """)
        XCTAssertEqual(numeric.templateFile?.fileId, "5")
        XCTAssertEqual(numeric.templateFile?.name, "양식.docx")

        let none = try decode("""
        {"slug":"t","type":"TEMPLATE","title":"양식"}
        """)
        XCTAssertNil(none.templateFile)
    }
}
