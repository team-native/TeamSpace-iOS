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
        try await request(Endpoint(method: .get, path: "posts/\(id)"), as: ServerPostDetailDTO.self).toEntity()
    }

    func toggleLike(postId: Int) async throws -> PostLike {
        let dto = try await request(Endpoint(method: .post, path: "posts/\(postId)/like"), as: ServerLikeResponseDTO.self)
        return PostLike(isLiked: dto.liked, likeCount: dto.likes)
    }

    func toggleCommentLike(postId: Int, commentId: Int) async throws -> PostLike {
        let endpoint = Endpoint(method: .post, path: "posts/\(postId)/comments/\(commentId)/like")
        let dto = try await request(endpoint, as: ServerLikeResponseDTO.self)
        return PostLike(isLiked: dto.liked, likeCount: dto.likes)
    }

    func report(postId: Int, reason: PostReportReason) async throws {
        let endpoint = Endpoint(
            method: .post,
            path: "posts/\(postId)/report",
            body: ServerReportRequestDTO(reason: reason.serverValue)
        )
        try await send(endpoint)
    }

    func deletePost(id: Int) async throws {
        try await send(Endpoint(method: .delete, path: "posts/\(id)"))
    }

    /// 분류 · 제목 · 본문 · 익명 · 댓글 정책만 보내요. `attachments` 를 빼면 서버가 사진을 그대로 둬요.
    func updatePost(id: Int, _ draft: PostDraft) async throws {
        let body = ServerPostPatchRequestDTO(
            category: (draft.category ?? .free).serverValue ?? "자유",
            title: draft.title,
            body: draft.body,
            anonymous: draft.isAnonymous,
            anonComments: draft.commentPolicy == .anonymous
        )
        try await send(Endpoint(method: .patch, path: "posts/\(id)", body: body))
    }

    /// 사진을 한 장씩 `POST /uploads` 로 올린 뒤, 받은 id 를 붙여 글을 써요.
    /// 서버는 `{id}` 만 돌려줘서 완료 화면에 쓸 글 정보는 보낸 값으로 채워요.
    func createPost(_ draft: PostDraft, images: [Data]) async throws -> PostSummary {
        var uploadIds: [String] = []
        for (index, image) in images.enumerated() {
            uploadIds.append(try await upload(image, index: index))
        }
        let category = draft.category ?? .free
        let body = ServerPostCreateRequestDTO(
            category: category.serverValue ?? "자유",
            title: draft.title,
            body: draft.body,
            anonymous: draft.isAnonymous,
            anonComments: draft.commentPolicy == .anonymous,
            attachments: uploadIds
        )
        let created = try await request(Endpoint(method: .post, path: "posts", body: body), as: ServerIdResponseDTO.self)
        return PostSummary(
            id: Int(created.id) ?? 0,
            category: category,
            title: draft.title,
            excerpt: ServerPostItemDTO.excerpt(of: draft.body),
            authorName: nil,
            authorRole: nil,
            isAnonymous: draft.isAnonymous,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            viewCount: 0,
            hasImage: !uploadIds.isEmpty,
            isMine: true
        )
    }

    func createComment(postId: Int, draft: CommentDraft) async throws -> PostComment {
        let endpoint = Endpoint(
            method: .post,
            path: "posts/\(postId)/comments",
            body: ServerCommentCreateRequestDTO(text: draft.body, anonymous: draft.isAnonymous)
        )
        return try await request(endpoint, as: ServerCommentDTO.self).toEntity(postAuthor: nil)
    }

    /// POST /uploads — JPG · PNG 만 (서버가 파일 앞부분을 확인해요)
    private func upload(_ image: Data, index: Int) async throws -> String {
        let isPNG = image.starts(with: [0x89, 0x50, 0x4E, 0x47])
        let file = MultipartFile(
            filename: "post-image-\(index + 1).\(isPNG ? "png" : "jpg")",
            mimeType: isPNG ? "image/png" : "image/jpeg",
            data: image
        )
        return try await request(Endpoint(method: .post, path: "uploads", file: file), as: ServerIdResponseDTO.self).id
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
