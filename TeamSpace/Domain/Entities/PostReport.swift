import Foundation

/// 신고 처리 상태 — 서버 `PENDING` · 숨김 · 삭제 · 반려
enum PostReportStatus: Equatable, Sendable {
    case pending
    case hidden
    case deleted
    case rejected
    case unknown(String)

    init(serverValue: String) {
        switch serverValue {
        case "PENDING": self = .pending
        case "숨김": self = .hidden
        case "삭제": self = .deleted
        case "반려": self = .rejected
        default: self = .unknown(serverValue)
        }
    }

    var title: String {
        switch self {
        case .pending: return "대기 중"
        case .hidden: return "숨김"
        case .deleted: return "삭제"
        case .rejected: return "반려"
        case .unknown(let value): return value
        }
    }
}

/// 신고 처리 결과 (POST /admin/reports/{id}/decision)
enum ReportDecision: String, CaseIterable, Sendable {
    case hide = "숨김"
    case delete = "삭제"
    case reject = "반려"

    var title: String {
        switch self {
        case .hide: return "글 숨기기"
        case .delete: return "글 삭제"
        case .reject: return "신고 반려"
        }
    }

    var status: PostReportStatus { PostReportStatus(serverValue: rawValue) }
}

/// 신고 관리 한 줄 — 서버는 글 제목을 주지 않아 글을 따로 불러 채워요. (숨김 · 삭제된 글은 nil)
struct PostReportItem: Equatable, Identifiable, Sendable {
    let id: Int
    let postId: Int
    /// 서버 사유 문자열 (예: "욕설·비하")
    let reason: String
    let detail: String
    var status: PostReportStatus
    var handledBy: String?
    var handledAt: Date?
    var postTitle: String?
}
