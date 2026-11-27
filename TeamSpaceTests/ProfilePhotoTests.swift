import XCTest
import UIKit
@testable import TeamSpace

/// 작성자 · 팀원 · 내 프로필 사진 — authorId · authorPhoto, /people photo 주소, PATCH /me photo
@MainActor
final class ProfilePhotoTests: XCTestCase {
    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testPhotoPathResolvesAgainstServer() throws {
        let base = try XCTUnwrap(URL(string: "https://api.example.com"))
        let photo = try XCTUnwrap(ProfilePhoto("/people/member-02/photo?v=ab12"))
        XCTAssertEqual(photo.url(relativeTo: base)?.absoluteString, "https://api.example.com/people/member-02/photo?v=ab12")

        let nested = try XCTUnwrap(URL(string: "https://example.com/api/"))
        XCTAssertEqual(photo.url(relativeTo: nested)?.absoluteString, "https://example.com/api/people/member-02/photo?v=ab12")

        XCTAssertEqual(ProfilePhoto("https://cdn.example.com/a.png")?.url(relativeTo: nil)?.absoluteString, "https://cdn.example.com/a.png")
        XCTAssertNil(ProfilePhoto(""), "빈 값이면 사진이 없어요")
        XCTAssertNil(ProfilePhoto("  "))
    }

    func testPostAuthorIdAndPhoto() throws {
        let json = #"""
        {"id":"7","category":"자유","title":"t","body":"b","anonymous":false,"createdAt":"2026-11-16T10:00:00+09:00",
         "author":"김민준","authorId":"member-02","authorPhoto":"/people/member-02/photo?v=1",
         "comments":[
           {"id":"1","text":"동명이인","createdAt":"2026-11-16T10:01:00+09:00","anonymous":false,"author":"김민준","authorId":"member-09","authorPhoto":""},
           {"id":"2","text":"글쓴이","createdAt":"2026-11-16T10:02:00+09:00","anonymous":false,"author":"김민준","authorId":"member-02","authorPhoto":"/people/member-02/photo?v=1"},
           {"id":"3","text":"익명","createdAt":"2026-11-16T10:03:00+09:00","anonymous":true,"author":"익명 1","anonymousNumber":1,"authorId":"","authorPhoto":""}
         ]}
        """#
        let detail = try JSONCoder.makeDecoder().decode(ServerPostDetailDTO.self, from: Data(json.utf8)).toEntity()

        XCTAssertEqual(detail.post.authorId, "member-02")
        XCTAssertEqual(detail.post.authorPhoto?.path, "/people/member-02/photo?v=1")
        XCTAssertEqual(detail.comments.map(\.isPostAuthor), [false, true, false], "이름이 같아도 id 가 다르면 글쓴이가 아니에요")
        XCTAssertNil(detail.comments[0].authorPhoto, "사진이 없으면 기본 이미지")
        XCTAssertNotNil(detail.comments[1].authorPhoto)
        XCTAssertNil(detail.comments[2].authorId, "익명 댓글은 작성자 정보를 비워요")
    }

    func testAnonymousPostHasNoAuthorInfo() throws {
        let json = #"{"id":"8","title":"t","body":"b","anonymous":true,"createdAt":"2026-11-16T10:00:00+09:00","authorId":"","authorPhoto":""}"#
        let post = try JSONCoder.makeDecoder().decode(ServerPostItemDTO.self, from: Data(json.utf8)).toEntity()
        XCTAssertNil(post.authorId)
        XCTAssertNil(post.authorPhoto)
    }

    func testProposerCommentUsesAuthorId() throws {
        let json = #"""
        {"id":"3","title":"t","body":"b","status":"접수","anonymous":false,"createdAt":"2026-11-16T10:00:00+09:00",
         "author":"이서윤","authorId":"member-05",
         "comments":[
           {"id":"1","text":"a","anonymous":false,"author":"이서윤","authorId":"member-11"},
           {"id":"2","text":"b","anonymous":false,"author":"이서윤","authorId":"member-05"}
         ]}
        """#
        let detail = try JSONCoder.makeDecoder().decode(ServerProposalDTO.self, from: Data(json.utf8)).toDetail()
        XCTAssertEqual(detail.comments.map(\.isProposer), [false, true])
    }

    func testPeoplePhotoUrl() throws {
        let json = #"{"id":"member-02","name":"안율","dept":"NativeOps","roles":["Member"],"photo":"/people/member-02/photo?v=9f"}"#
        let member = try JSONCoder.makeDecoder().decode(ServerPersonDTO.self, from: Data(json.utf8)).toEntity()
        XCTAssertEqual(member.photo?.path, "/people/member-02/photo?v=9f")

        let empty = #"{"id":"member-03","name":"양지우","dept":"","roles":[],"photo":""}"#
        XCTAssertNil(try JSONCoder.makeDecoder().decode(ServerPersonDTO.self, from: Data(empty.utf8)).toEntity().photo)
    }

    func testProfilePatchSendsPhotoOnlyWhenChanged() throws {
        func object(_ change: ProfilePhotoChange) throws -> [String: Any] {
            let update = ProfileUpdate(intro: "", interests: [], avatarBackground: .white, photo: change)
            let body = try JSONEncoder().encode(ServerProfilePatchRequestDTO(update))
            return try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        }
        XCTAssertNil(try object(.keep)["photo"], "그대로 두면 photo 를 안 보내요")
        XCTAssertEqual(try object(.remove)["photo"] as? String, "", "지우면 빈 문자열")
        XCTAssertEqual(try object(.upload(data: Data([1, 2, 3]), mimeType: "image/jpeg"))["photo"] as? String, "data:image/jpeg;base64,AQID")
        XCTAssertEqual(try object(.keep)["avatarBackground"] as? String, "WHITE")
    }

    func testProfileDecodesPhotoAndWhite() throws {
        let json = #"{"id":"1","name":"옥물결","dept":"Design","avatarBackground":"WHITE","photo":"/people/member-01/photo?v=2"}"#
        let profile = try JSONCoder.makeDecoder().decode(ServerProfileDTO.self, from: Data(json.utf8)).toEntity()
        XCTAssertEqual(profile.avatarBackground, .white)
        XCTAssertEqual(profile.photo?.path, "/people/member-01/photo?v=2")
        XCTAssertTrue(AvatarBackground.selectable.contains(.white))
    }

    func testUploadThenRemovePhoto() async throws {
        let container = makeContainer()
        let viewModel = container.makeProfileEditViewModel()
        await viewModel.load()
        XCTAssertNil(viewModel.profile?.photo)

        let image = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 800)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 800))
        }
        viewModel.setAvatarImage(image.pngData())
        let picked = try XCTUnwrap(viewModel.avatarImageData.flatMap(UIImage.init(data:)))
        XCTAssertLessThanOrEqual(max(picked.size.width, picked.size.height), ProfilePhotoEncoder.maxDimension, "올리기 전에 줄여요")
        XCTAssertTrue(viewModel.hasChanges)

        await viewModel.save()
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.profile?.photo, "서버가 사진 주소를 돌려줘요")
        XCTAssertEqual(viewModel.currentPhoto, viewModel.profile?.photo)

        let reloaded = container.makeProfileEditViewModel()
        await reloaded.load()
        reloaded.resetAvatar()
        XCTAssertNil(reloaded.currentPhoto, "기본 이미지로 바꾸면 바로 기본 얼굴")
        XCTAssertTrue(reloaded.hasChanges)
        await reloaded.save()
        XCTAssertNil(reloaded.profile?.photo, "저장하면 서버 사진도 지워져요")
    }

    func testBrokenImageShowsError() async {
        let viewModel = makeContainer().makeProfileEditViewModel()
        await viewModel.load()
        viewModel.setAvatarImage(Data([0, 1, 2]))
        XCTAssertEqual(viewModel.errorMessage, "이미지를 불러오지 못했어요. 다른 이미지를 골라 주세요.")
        XCTAssertNil(viewModel.avatarImageData)
    }
}
