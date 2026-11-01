import Foundation

final class BoardRepositoryImpl: BoardRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchPosts(_ query: PostListQuery, cursor: String?, limit: Int) async throws -> CursorPage<PostSummary> {
        let endpoint = Endpoint(method: .get, path: "posts", queryItems: query.queryItems(cursor: cursor, limit: limit))
        let page = try await request(endpoint, as: CursorPageDTO<ServerPostItemDTO>.self)
        return CursorPage(items: page.items.map { $0.toEntity() }, nextCursor: page.nextCursor)
    }

    func fetchPinnedNotices(limit: Int) async throws -> [NoticeSummary] {
        let endpoint = Endpoint(method: .get, path: "notices", queryItems: [
            URLQueryItem(name: "pinned", value: "true"),
            URLQueryItem(name: "limit", value: String(limit))
        ])
        return try await request(endpoint, as: CursorPageDTO<ServerNoticeItemDTO>.self).items.map { $0.toEntity() }
    }

    /// 서버엔 검색 전용 API 가 없어 게시글 · 공지 목록에 `q` 를 붙여 같이 불러요.
    func search(keyword: String) async throws -> BoardSearchResult {
        async let posts = fetchPosts(PostListQuery(period: .all, keyword: keyword), cursor: nil, limit: Self.searchLimit)
        async let notices = request(
            Endpoint(method: .get, path: "notices", queryItems: [
                URLQueryItem(name: "q", value: keyword),
                URLQueryItem(name: "limit", value: String(Self.searchLimit))
            ]),
            as: CursorPageDTO<ServerNoticeItemDTO>.self
        )
        return BoardSearchResult(notices: try await notices.items.map { $0.toEntity() }, posts: try await posts.items)
    }

    static let searchLimit = 50

    func fetchPost(id: Int) async throws -> PostDetail {
        try await request(Endpoint(method: .get, path: "posts/\(id)"), as: PostDetailDTO.self).toEntity()
    }

    func toggleLike(postId: Int) async throws -> PostLike {
        let dto = try await request(Endpoint(method: .post, path: "posts/\(postId)/like"), as: PostLikeResponseDTO.self)
        return PostLike(isLiked: dto.isLiked, likeCount: dto.likeCount)
    }

    func report(postId: Int, reason: PostReportReason) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "posts/\(postId)/reports",
            body: PostReportRequestDTO(reason: reason.rawValue)
        )
        try await send(endpoint)
    }

    func deletePost(id: Int) async throws {
        try await send(Endpoint(method: .delete, path: "posts/\(id)"))
    }

    func createPost(_ draft: PostDraft, images: [Data]) async throws -> PostSummary {
        let body = PostCreateRequestDTO(
            isAnonymous: draft.isAnonymous,
            category: draft.category ?? .free,
            title: draft.title,
            body: draft.body,
            commentPolicy: draft.commentPolicy,
            images: images.map { $0.base64EncodedString() }
        )
        return try await request(Endpoint(method: .post, path: "posts", body: body), as: PostSummaryDTO.self).toEntity()
    }

    func createComment(postId: Int, draft: CommentDraft) async throws -> PostComment {
        let endpoint = Endpoint(
            method: .post,
            path: "posts/\(postId)/comments",
            body: CommentCreateRequestDTO(body: draft.body, isAnonymous: draft.isAnonymous)
        )
        return try await request(endpoint, as: PostCommentDTO.self).toEntity()
    }

    /// 응답 본문이 없어도 되는 요청
    private func send(_ endpoint: Endpoint) async throws {
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch NetworkError.emptyData {
            return
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
