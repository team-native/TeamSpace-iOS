import UIKit
import XCTest
@testable import TeamSpace

/// 백엔드 API 맞추기 48 — 게시글 첨부 사진 보여주기 (GET /posts/{id} attachments → GET /uploads/{id})
@MainActor
final class PostImageTests: XCTestCase {
    private func makeContainer(defaultsName: String = #function) -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let defaults = UserDefaults(suiteName: "test.postImage.\(defaultsName)") ?? .standard
        defaults.removeObject(forKey: UserDefaultsPostDraftRepository.key)
        return DIContainer(
            apiClient: APIClient(
                baseURL: MockTransport.baseURL,
                transport: MockTransport(latencyNanoseconds: 0),
                tokenStorage: tokenStorage
            ),
            tokenStorage: tokenStorage,
            postDraftRepository: UserDefaultsPostDraftRepository(defaults: defaults)
        )
    }

    func testDetailReadsAttachedPhotos() async throws {
        let detail = makeContainer().makePostDetailViewModel(postId: 36)
        await detail.load()
        let images = try XCTUnwrap(detail.detail?.images)
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(images.first?.fileId, "\(MockUploadStore.samplePhotoPrefix)36")
        XCTAssertTrue(images.first?.canDownload == true)
        XCTAssertNotNil(detail.attachmentDownloader)
    }

    func testPostWithoutPhotosHasNoImages() async throws {
        let detail = makeContainer().makePostDetailViewModel(postId: 39)
        await detail.load()
        XCTAssertNotNil(detail.detail)
        XCTAssertEqual(detail.detail?.images, [])
    }

    func testPrefetchKeepsPhotoAndOpenReusesIt() async throws {
        let detail = makeContainer().makePostDetailViewModel(postId: 35)
        await detail.load()
        let file = try XCTUnwrap(detail.detail?.images.first)
        let downloader = try XCTUnwrap(detail.attachmentDownloader)

        await downloader.prefetch(file)

        let url = try XCTUnwrap(downloader.localURLs[file.id])
        XCTAssertNotNil(UIImage(contentsOfFile: url.path), "PNG 로 읽혀요")
        await downloader.open(file)
        XCTAssertEqual(downloader.previewURL, url, "받아 둔 파일로 바로 열어요")
        XCTAssertNil(downloader.errorMessage)
    }

    func testPublishedPhotoShowsInDetail() async throws {
        let container = makeContainer()
        let compose = container.makePostComposeViewModel()
        compose.draft.category = .info
        compose.draft.title = "사진 글"
        compose.draft.body = "사진을 붙였어요"
        compose.addImages([MockUploadStore.samplePhoto])
        await compose.publish()
        let post = try XCTUnwrap(compose.publishedPost)

        let detail = container.makePostDetailViewModel(postId: post.id)
        await detail.load()
        let file = try XCTUnwrap(detail.detail?.images.first)
        let downloader = try XCTUnwrap(detail.attachmentDownloader)
        await downloader.prefetch(file)
        let url = try XCTUnwrap(downloader.localURLs[file.id])
        XCTAssertEqual(try Data(contentsOf: url), MockUploadStore.samplePhoto)
    }

    func testUrlOnlyAttachmentAndMissingFile() async throws {
        let json = """
        {"id":"9","category":"자유","title":"t","body":"b","createdAt":"2026-11-04T10:00:00+09:00",
         "attachments":[{"url":"/uploads/404","filename":"gone.png","size":10,"contentType":"image/png"}]}
        """
        let dto = try JSONCoder.makeDecoder().decode(ServerPostDetailDTO.self, from: Data(json.utf8))
        let file = try XCTUnwrap(dto.toEntity().images.first)
        XCTAssertEqual(file.fileId, "404")

        let downloader = makeContainer().makeAttachmentDownloadViewModel()
        await downloader.prefetch(file)
        XCTAssertNil(downloader.localURLs[file.id])
        XCTAssertTrue(downloader.failedIds.contains(file.id), "자리에 실패 안내를 보여요")
        XCTAssertNil(downloader.errorMessage, "썸네일 실패는 알림을 띄우지 않아요")
    }
}
