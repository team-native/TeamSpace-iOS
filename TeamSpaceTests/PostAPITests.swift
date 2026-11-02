import XCTest
@testable import TeamSpace

/// 백엔드 API 맞추기 4 — 게시글 작성 · 공감 · 신고 · 댓글 (TeamSpace-backend develop `community.py` · `admin.py`)
final class PostAPITests: XCTestCase {
    private func makeRepository(_ transport: ScriptedTransport) -> BoardRepositoryImpl {
        BoardRepositoryImpl(client: APIClient(baseURL: MockTransport.baseURL, transport: transport, tokenStorage: InMemoryTokenStorage()))
    }

    private func json(_ request: URLRequest?) throws -> [String: Any] {
        try XCTUnwrap(request?.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
    }

    func testCreatePostUploadsImagesThenSendsIds() async throws {
        let transport = ScriptedTransport(responses: [
            "uploads": #"{"id":"u1","url":"/uploads/u1","filename":"a.jpg","size":4}"#,
            "posts": #"{"id":"77"}"#
        ])
        var draft = PostDraft()
        draft.category = .info
        draft.title = "제목"
        draft.body = "본문"
        draft.isAnonymous = false
        draft.commentPolicy = .realName
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0])

        let post = try await makeRepository(transport).createPost(draft, images: [jpeg, jpeg])

        let requests = await transport.requests
        XCTAssertEqual(requests.map { $0.url?.lastPathComponent }, ["uploads", "uploads", "posts"])
        XCTAssertTrue(requests[0].value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
        let multipart = String(decoding: requests[0].httpBody ?? Data(), as: UTF8.self)
        XCTAssertTrue(multipart.contains(#"name="file"; filename="post-image-1.jpg""#))
        XCTAssertTrue(multipart.contains("Content-Type: image/jpeg"))

        let body = try json(requests.last)
        XCTAssertEqual(body["category"] as? String, "정보 공유")
        XCTAssertEqual(body["anonymous"] as? Bool, false)
        XCTAssertEqual(body["anonComments"] as? Bool, false)
        XCTAssertEqual(body["attachments"] as? [String], ["u1", "u1"])
        XCTAssertEqual(body["status"] as? String, "published")
        XCTAssertEqual(post.id, 77)
        XCTAssertTrue(post.hasImage)
    }

    func testLikeReportAndCommentUseServerShapes() async throws {
        let transport = ScriptedTransport(responses: [
            "like": #"{"liked":true,"likes":13}"#,
            "report": #"{"id":"5","status":"PENDING"}"#,
            "comments": #"{"id":"901","postId":"41","anonymous":true,"text":"좋아요","createdAt":"2026-11-02T01:20:00.5","likes":0,"replyTo":null,"mine":true}"#
        ])
        let repository = makeRepository(transport)

        let like = try await repository.toggleLike(postId: 41)
        try await repository.report(postId: 41, reason: .spam)
        let comment = try await repository.createComment(postId: 41, draft: CommentDraft(isAnonymous: true, body: "좋아요"))

        XCTAssertEqual(like, PostLike(isLiked: true, likeCount: 13))
        let requests = await transport.requests
        XCTAssertEqual(requests[1].url?.lastPathComponent, "report")
        XCTAssertEqual(try json(requests[1])["reason"] as? String, "도배·광고")
        XCTAssertEqual(try json(requests[2])["text"] as? String, "좋아요")
        XCTAssertEqual(try json(requests[2])["anonymous"] as? Bool, true)
        XCTAssertEqual(comment.id, 901)
        XCTAssertTrue(comment.isAnonymous)
        XCTAssertTrue(comment.isMine)
    }
}

/// 마지막 경로 이름별로 정해진 응답을 주고, 받은 요청을 순서대로 기억해요.
private actor ScriptedTransport: HTTPTransport {
    private let responses: [String: String]
    private(set) var requests: [URLRequest] = []

    init(responses: [String: String]) {
        self.responses = responses
    }

    nonisolated func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await record(request)
    }

    private func record(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard let url = request.url, let json = responses[url.lastPathComponent],
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        else { throw URLError(.badURL) }
        return (Data(json.utf8), response)
    }
}
