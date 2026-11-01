import SwiftUI

extension ProposalStatus: BadgeRepresentable {
    var badgeTitle: String { title }

    var badgeTone: BadgeTone {
        switch self {
        case .reviewing: return .primary
        case .answered, .adopted: return .positive
        case .closed, .unknown: return .neutral
        }
    }
}

extension MyPost {
    /// "2026.10.15 18:20 · 실명 옥물결" / "2026.10.12 13:10 · 나만 보는 익명 기록"
    func metaText(authorName: String) -> String {
        let when = "\(TSFormat.fullDate(createdAt)) \(TSFormat.time(createdAt))"
        return isAnonymous ? "\(when) · 나만 보는 익명 기록" : "\(when) · 실명 \(authorName)"
    }

    /// "좋아요 8 · 댓글 3 · 조회 41" / "… · 공개 표시: 익명" / "… · 첨부 1개"
    var statsText: String {
        let tail: String
        if isAnonymous {
            tail = "공개 표시: 익명"
        } else if attachmentCount > 0 {
            tail = "첨부 \(attachmentCount)개"
        } else {
            tail = "조회 \(viewCount)"
        }
        return "좋아요 \(likeCount) · 댓글 \(commentCount) · \(tail)"
    }

    var badgeTitle: String { isAnonymous ? "익명" : "실명" }
}

extension MyComment {
    var badgeTitle: String { isAnonymous ? "익명 댓글 · 내 기록" : "실명 댓글" }

    /// "“예약 기준이 정리되면 좋겠어요.”"
    var quoteText: String { "“\(body)”" }

    /// "회의실 이용 경험을 나눠주세요 · 10.14 17:05\n좋아요 2 · 답글 1 · 공개 화면에는 익명으로 표시"
    var metaText: String {
        let first = "\(postTitle) · \(TSFormat.shortDate(createdAt)) \(TSFormat.time(createdAt))"
        let display = isAnonymous ? "공개 화면에는 익명으로 표시" : "실명으로 표시"
        return "\(first)\n좋아요 \(likeCount) · 답글 \(replyCount) · \(display)"
    }
}

extension MyProposal {
    /// "10.09 · 옥물결"
    var headerText: String { "\(TSFormat.shortDate(createdAt)) · \(authorName)" }

    var linkTitle: String {
        status == .answered ? "운영 답변 확인" : "상세 · 검토 현황 보기"
    }
}

/// 07-10 글 · 댓글 탭
enum MyPostsTab: Hashable, CaseIterable {
    case posts
    case comments
}

/// 07-11 상태 칩 (nil = 전체)
enum ProposalFilter: Hashable, CaseIterable {
    case all
    case reviewing
    case answered

    var status: ProposalStatus? {
        switch self {
        case .all: return nil
        case .reviewing: return .reviewing
        case .answered: return .answered
        }
    }

    var title: String {
        switch self {
        case .all: return "전체"
        case .reviewing: return "검토 중"
        case .answered: return "답변 완료"
        }
    }
}
