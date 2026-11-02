import Foundation

/// GET /me/activity 의 한 항목 — `{id, kind, title, createdAt, href}` (TeamSpace-backend develop `space.my_activity`)
/// kind: approval · post · comment · inquiry · proposal · todo · application · event_rsvp
struct ServerActivityItemDTO: Decodable {
    let id: Int
    let kind: String
    let title: String
    let createdAt: Date?
    let href: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        kind = (try? container.decodeIfPresent(String.self, forKey: .kind)) ?? ""
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? ""
        createdAt = (try? container.decodeIfPresent(String.self, forKey: .createdAt)).flatMap { $0.flatMap(ServerDate.parse) }
        href = (try? container.decodeIfPresent(String.self, forKey: .href)) ?? ""
    }

    private enum CodingKeys: String, CodingKey { case id, kind, title, createdAt, href }

    /// 07-10 내가 쓴 댓글 — 서버는 댓글 내용(title)만 줘서 글 제목 · 좋아요 · 답글 수는 비어요. 글 id 는 href 끝 숫자.
    func toComment() -> MyComment? {
        guard kind == "comment" else { return nil }
        let postId = href.split(separator: "/").last.flatMap { Int($0) }
        return MyComment(
            id: id, postId: postId, postTitle: "", body: title, createdAt: createdAt ?? Date(timeIntervalSince1970: 0),
            isAnonymous: false, likeCount: 0, replyCount: 0
        )
    }
}

extension ServerMeSummaryDTO {
    /// 07-12 내 활동 숫자
    func toActivitySummary() -> ActivitySummary {
        ActivitySummary(
            unreadNotificationCount: unreadNotifications,
            submittedDocumentCount: submittedApprovals,
            postCount: myPosts,
            inquiryCount: myInquiries
        )
    }
}

extension ServerPostItemDTO {
    /// 07-10 내가 쓴 글
    func toMyPost() -> MyPost {
        MyPost(
            id: id, title: title, createdAt: createdAt, isAnonymous: anonymous, likeCount: likes,
            commentCount: commentCount, viewCount: views, attachmentCount: attachmentCount
        )
    }
}

extension ServerProposalDTO {
    /// 07-11 내가 쓴 제안
    func toMyProposal() -> MyProposal {
        MyProposal(
            id: id, category: category, title: title, body: body, authorName: anonymous ? "익명" : (author ?? ""),
            createdAt: createdAt, status: ProposalStatus(serverValue: status), recommendCount: recommendCount,
            commentCount: commentCount
        )
    }
}
