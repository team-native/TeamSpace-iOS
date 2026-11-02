import Foundation

/// 10 팀 게시판 가짜 저장소 — Figma 10-1 수정본 · 10-12 예시 (날짜는 오늘 기준)
/// 내 글(31 · 28 · 25)은 07-10 내가 쓴 게시글, 고정 공지(41 · 42)는 02-1 홈 공지와 같은 ID 예요.
final class MockBoardStore: @unchecked Sendable {
    /// 10-12 최근 검색어 기본값
    static let recentKeywords = ["정산 기준", "체크리스트", "계약서", "회의실"]

    private let lock = NSLock()
    private let now: Date
    private var posts: [PostSummaryDTO] = []
    /// 고정 공지 · 검색에 쓰는 공지 (10-5 공지와 같은 저장소)
    let noticeStore: MockNoticeStore
    /// 10-1 고정 공지로 보여줄 공지
    private static let pinnedNoticeIds = [41, 42]
    private var likedIds: Set<Int> = []
    private var comments: [Int: [PostCommentDTO]] = [:]
    /// 새로 쓴 글의 본문 · 댓글 정책
    private var bodies: [Int: String] = [:]
    private var policies: [Int: CommentPolicy] = [:]
    /// Mock 로그인 사용자 (07 내 공간과 같은 사람)
    private static let me = (name: "옥물결", role: "iOS")
    /// 신고 접수 내역 (게시글 ID · 사유)
    private var reports: [(postId: Int, reason: String)] = []

    init(now: Date = Date()) {
        self.now = now
        self.noticeStore = MockNoticeStore(now: now)
        let today = Calendar.current.startOfDay(for: now)
        func at(_ daysAgo: Double, _ hour: Double) -> Date {
            today.addingTimeInterval(-daysAgo * 86_400 + hour * 3_600)
        }
        posts = Self.seedPosts(at: at)
        comments = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, Self.seedComments(for: $0)) })
    }

    /// 10-3 댓글 — 41번은 Figma 예시, 나머지는 댓글 수만큼 만들어요.
    private static func seedComments(for post: PostSummaryDTO) -> [PostCommentDTO] {
        if post.id == 41 {
            return [
                PostCommentDTO(id: 4101, authorName: nil, isAnonymous: true, anonymousNumber: 1, isPostAuthor: false,
                               isMine: false, body: "발로랑겜입니다개발이답입니다", createdAt: post.createdAt.addingTimeInterval(14 * 60)),
                PostCommentDTO(id: 4102, authorName: nil, isAnonymous: true, anonymousNumber: 2, isPostAuthor: true,
                               isMine: false, body: "취업을 바라보며 게임은 휴지통으로", createdAt: post.createdAt.addingTimeInterval(21 * 60))
            ]
        }
        let names = ["이시우", "양지우", "김민준", "안율"]
        let bodies = ["좋은 의견 감사해요!", "저도 같은 생각이에요.", "다음 회의 때 같이 이야기해봐요.", "정리해 주셔서 도움이 됐어요."]
        return (0..<post.commentCount).map { index in
            PostCommentDTO(
                id: post.id * 100 + index + 1,
                authorName: post.isAnonymous ? nil : names[index % names.count],
                isAnonymous: post.isAnonymous,
                anonymousNumber: post.isAnonymous ? index + 1 : nil,
                isPostAuthor: false,
                isMine: false,
                body: bodies[index % bodies.count],
                createdAt: post.createdAt.addingTimeInterval(Double(index + 1) * 30 * 60)
            )
        }
    }

    private static func seedPosts(at: (Double, Double) -> Date) -> [PostSummaryDTO] {
        func post(
            _ id: Int, _ category: PostCategory, _ title: String, _ excerpt: String, author: (String, String)?,
            _ date: Date, likes: Int, comments: Int, views: Int, image: Bool = false, mine: Bool = false
        ) -> PostSummaryDTO {
            PostSummaryDTO(
                id: id, category: category, title: title, excerpt: excerpt,
                authorName: author?.0, authorRole: author?.1, isAnonymous: author == nil, createdAt: date,
                likeCount: likes, commentCount: comments, viewCount: views, hasImage: image, isMine: mine
            )
        }
        let me = (Self.me.name, Self.me.role)
        return [
            post(41, .question, "게임에 대해서 어떻게 생각하시나요",
                 "저는 발로를 끊었더니 진짜 죽을맛입니다. 그래도 취업을 위해서라면…",
                 author: nil, at(0, 9.33), likes: 12, comments: 2, views: 48),
            post(40, .free, "회식 이시우가 쏘는 거 어떤가요?",
                 "이시우가 젤 많이 먹으니 쏘는 게 합당하다고 생각합니다. 기대하겠습니다.",
                 author: ("김민준", "Leader"), at(0, 8.75), likes: 8, comments: 4, views: 35),
            post(39, .question, "스터디 활동 다들 잘 하고 계신가요?", "TIL을 열심히 올려야 지우가 좋아합니다 화이팅^^",
                 author: nil, at(1, 17.17), likes: 15, comments: 6, views: 52),
            post(31, .free, "이번 주 함께 읽을 책 추천해요", "이번 주 컬처 시간에 함께 읽을 책을 골라봤어요.",
                 author: me, at(1, 18.33), likes: 8, comments: 3, views: 41, mine: true),
            post(36, .info, "신입 팀원을 위한 외주 견적 팁", "처음 견적을 낼 때 놓치기 쉬운 항목을 정리했어요.",
                 author: nil, at(2, 14), likes: 33, comments: 9, views: 97, image: true),
            post(35, .info, "NativeLab 스터디 후기 공유합니다", "이번 기수 스터디에서 배운 점을 나눠요.",
                 author: ("이시우", "PM"), at(3, 20), likes: 27, comments: 5, views: 76, image: true),
            post(37, .free, "정산 내역 공개 범위 제안드려요", "월 정산 내역을 어디까지 공개할지 의견을 모아요.",
                 author: nil, at(4, 11), likes: 18, comments: 6, views: 64),
            post(28, .question, "집중해서 일하는 시간, 어떻게 정하나요?", "집중 시간을 정해두는 팀원분들의 방법이 궁금해요.",
                 author: nil, at(4, 13.17), likes: 12, comments: 6, views: 88, mine: true),
            post(34, .question, "외주 정산 서류 어디까지 챙기나요?", "계약서 말고도 챙겨야 할 서류가 있을까요?",
                 author: ("이시우", "PM"), at(6, 11), likes: 9, comments: 3, views: 40),
            post(25, .info, "디자인 리뷰 자료 공유합니다!", "지난 리뷰에서 나온 피드백을 정리한 자료예요.",
                 author: me, at(7, 9.5), likes: 5, comments: 2, views: 30, image: true, mine: true),
            post(22, .free, "회의실 이용 경험을 나눠주세요",
                 "예약할 때 불편했던 점과 개선 의견이 있나요? 팀원 여러분의 경험을 듣고 싶어요.",
                 author: ("김민규", "NativeOps"), at(12, 10), likes: 6, comments: 4, views: 57),
            post(20, .free, "10월 정기 회의 후기", "멘토링 공유 시간이 특히 좋았어요.",
                 author: ("김민준", "Leader"), at(15, 16), likes: 10, comments: 5, views: 61),
            post(30, .info, "9월 정산 후기와 개선점", "9월 정산을 돌아보고 개선할 점을 정리했어요.",
                 author: nil, at(16, 15), likes: 12, comments: 5, views: 70),
            post(18, .question, "툴 구독 정리 의견", "중복 구독을 줄일 방법이 있을까요?",
                 author: nil, at(20, 11), likes: 7, comments: 3, views: 33)
        ]
    }

    /// GET /posts — 서버(develop) 형식 `{items, nextCursor}`. 분류 · 기간 · 정렬 · 검색 · `o:N` 커서를 흉내 내요.
    func listJSON(query: [String: String], now: Date = Date()) -> String {
        lock.lock()
        defer { lock.unlock() }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var items = posts
        if query["mine"] == "true" { items = items.filter(\.isMine) }
        if let category = query["category"] {
            items = items.filter { $0.category == PostCategory(serverValue: category) }
        }
        switch query["period"] ?? "all" {
        case "today": items = items.filter { $0.createdAt >= today }
        case "week": items = items.filter { $0.createdAt >= now.addingTimeInterval(-7 * 86_400) }
        case "month": items = items.filter { $0.createdAt >= now.addingTimeInterval(-30 * 86_400) }
        default: break
        }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        if let from = query["from"].flatMap(dayFormatter.date(from:)) {
            items = items.filter { $0.createdAt >= from }
        }
        if let to = query["to"].flatMap(dayFormatter.date(from:)) {
            items = items.filter { $0.createdAt < to.addingTimeInterval(86_400) }
        }
        if let keyword = query["q"]?.trimmingCharacters(in: .whitespacesAndNewlines), !keyword.isEmpty {
            items = items.filter { post in
                [post.title, bodies[post.id] ?? post.excerpt].contains { $0.localizedCaseInsensitiveContains(keyword) }
            }
        }
        if query["sort"] == "likes" {
            items.sort { ($0.likeCount, $0.createdAt, $0.id) > ($1.likeCount, $1.createdAt, $1.id) }
        } else {
            items.sort { ($0.createdAt, $0.id) > ($1.createdAt, $1.id) }
        }
        let start = query["cursor"].flatMap { $0.hasPrefix("o:") ? Int($0.dropFirst(2)) : nil } ?? 0
        let limit = query["limit"].flatMap(Int.init) ?? 20
        let page = Array(items.dropFirst(start).prefix(limit))
        let next = start + limit < items.count ? "\"o:\(start + limit)\"" : "null"
        let rows = page.map { serverItemJSON($0) }.joined(separator: ",")
        return #"{"items":[\#(rows)],"nextCursor":\#(next)}"#
    }

    /// 서버 `_post_view` 모양 — id 는 문자열, 날짜는 Python isoformat(마이크로초) 처럼
    private func serverItemJSON(_ post: PostSummaryDTO) -> String {
        Self.json(serverItemFields(post))
    }

    private static func json(_ object: Any) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    private func serverItemFields(_ post: PostSummaryDTO) -> [String: Any] {
        let category: String = post.category.serverValue ?? "자유"
        let body: String = bodies[post.id] ?? post.excerpt
        let commentCount: Int = comments[post.id]?.count ?? post.commentCount
        let attachments: [[String: String]] = post.hasImage ? [["id": "upload-\(post.id)"]] : []
        let createdAt: String = Self.pythonISO(post.createdAt)
        var fields: [String: Any] = [:]
        fields["id"] = String(post.id)
        fields["category"] = category
        fields["title"] = post.title
        fields["body"] = body
        fields["anonymous"] = post.isAnonymous
        fields["anonComments"] = post.isAnonymous
        fields["views"] = post.viewCount
        fields["likes"] = post.likeCount
        fields["pinned"] = false
        fields["mine"] = post.isMine
        fields["commentCount"] = commentCount
        fields["attachments"] = attachments
        fields["createdAt"] = createdAt
        fields["when"] = createdAt
        if !post.isAnonymous, let author = post.authorName { fields["author"] = author }
        return fields
    }

    /// 서버 `_comment_view` 모양 — 익명 글에서 글쓴이 댓글은 author 가 "글쓴이"
    private func serverCommentFields(_ comment: PostCommentDTO, postId: Int, postAnonymous: Bool) -> [String: Any] {
        var fields: [String: Any] = [:]
        fields["id"] = String(comment.id)
        fields["postId"] = String(postId)
        fields["anonymous"] = comment.isAnonymous
        fields["text"] = comment.body
        fields["createdAt"] = Self.pythonISO(comment.createdAt)
        fields["when"] = Self.pythonISO(comment.createdAt)
        fields["likes"] = 0
        fields["replyTo"] = NSNull()
        fields["mine"] = comment.isMine
        if postAnonymous && comment.isPostAuthor {
            fields["author"] = "글쓴이"
        } else if !comment.isAnonymous {
            fields["author"] = comment.authorName ?? Self.me.name
        }
        return fields
    }

    /// `2026-11-02T01:20:00.123456+00:00`
    static func pythonISO(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'000+00:00'"
        return formatter.string(from: date)
    }

    /// GET /notices?pinned=true — 10-1 고정 공지(41 · 42)
    func pinnedNoticesJSON() -> String {
        noticeStore.serverItemsJSON(ids: Self.pinnedNoticeIds)
    }

    /// GET /posts/{id} — 볼 때마다 조회 수가 1 올라가요. (서버 형식)
    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return nil }
        posts[index].viewCount += 1
        let post = posts[index]
        var fields = serverItemFields(post)
        fields["body"] = bodies[id] ?? Self.body(for: post)
        fields["anonComments"] = (policies[id] ?? (post.isAnonymous ? .anonymous : .realName)) == .anonymous
        fields["comments"] = (comments[id] ?? []).map { serverCommentFields($0, postId: id, postAnonymous: post.isAnonymous) }
        return Self.json(fields)
    }

    /// POST /posts — 내 글로 맨 앞에 추가하고 `{id}` 만 돌려줘요.
    func create(_ request: ServerPostCreateRequestDTO) -> String {
        lock.lock()
        defer { lock.unlock() }
        let id = (posts.map(\.id).max() ?? 0) + 1
        let post = PostSummaryDTO(
            id: id, category: PostCategory(serverValue: request.category), title: request.title,
            excerpt: ServerPostItemDTO.excerpt(of: request.body),
            authorName: request.anonymous ? nil : Self.me.name, authorRole: nil,
            isAnonymous: request.anonymous, createdAt: Date(), likeCount: 0, commentCount: 0, viewCount: 0,
            hasImage: !request.attachments.isEmpty, isMine: true
        )
        posts.insert(post, at: 0)
        bodies[id] = request.body
        policies[id] = request.anonComments ? .anonymous : .realName
        comments[id] = []
        return #"{"id":"\#(id)"}"#
    }

    /// POST /posts/{id}/comments — 익명 글의 글쓴이는 익명으로 남아요. (서버 형식)
    func createComment(postId: Int, request: ServerCommentCreateRequestDTO) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return nil }
        let post = posts[index]
        let existing = comments[postId] ?? []
        let isPostAuthor = post.isMine
        let isAnonymous = request.anonymous || policies[postId] == .anonymous || (post.isAnonymous && isPostAuthor)
        let comment = PostCommentDTO(
            id: (existing.map(\.id).max() ?? postId * 100) + 1,
            authorName: isAnonymous ? nil : Self.me.name,
            isAnonymous: isAnonymous,
            anonymousNumber: nil,
            isPostAuthor: isPostAuthor,
            isMine: true,
            body: request.text,
            createdAt: Date()
        )
        comments[postId] = existing + [comment]
        posts[index].commentCount += 1
        return Self.json(serverCommentFields(comment, postId: postId, postAnonymous: post.isAnonymous))
    }

    /// POST /posts/{id}/like
    func toggleLike(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return nil }
        let isLiked = !likedIds.contains(id)
        if isLiked { likedIds.insert(id) } else { likedIds.remove(id) }
        posts[index].likeCount += isLiked ? 1 : -1
        return #"{"liked":\#(isLiked),"likes":\#(posts[index].likeCount)}"#
    }

    /// POST /posts/{id}/report — 내 글이면 false (403)
    func report(id: Int, reason: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let post = posts.first(where: { $0.id == id }), !post.isMine else { return false }
        reports.append((id, reason))
        return true
    }

    /// DELETE /posts/{id} — 내 글만 지워져요.
    func delete(id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = posts.firstIndex(where: { $0.id == id }), posts[index].isMine else { return false }
        posts.remove(at: index)
        comments[id] = nil
        return true
    }

    private static func body(for post: PostSummaryDTO) -> String {
        guard post.id == 41 else { return "\(post.excerpt)\n\n자유롭게 의견 남겨주세요." }
        return """
        저는 발로를 끊었더니 진짜 죽을맛입니다.
        다이아는 찍고 접고 싶었는데...

        그래도 취업을 위해서라면 ㅎㅇㅌ
        제 친구들이 게임하는 거 볼 때마다 저도 너무 하고 싶어집니다.
        게임중독 탈출 방안 없을까요
        """
    }

    private func envelope<T: Encodable>(_ value: T) -> String {
        #"{"code":200,"message":"성공","data":\#(encode(value))}"#
    }

    private func encode<T: Encodable>(_ value: T) -> String {
        (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
    }
}
