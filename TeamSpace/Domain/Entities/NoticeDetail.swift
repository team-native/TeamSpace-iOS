import Foundation

/// 10-6 공지 상세
struct NoticeDetail: Equatable, Sendable {
    let notice: NoticeSummary
    let authorName: String
    /// 예) "FA" — 서버가 주지 않으면 nil
    let authorRole: String?
    let body: String
    /// 서버가 조회 수를 주지 않으면 nil
    let viewCount: Int?
    /// 본문과 함께 보는 문서함 문서
    let linkedDocument: NoticeLinkedDocument?
    /// 필독 확인 여부 (서버 `confirmedByMe`)
    var isAcknowledged: Bool
    /// 이번에 확인한 시각 — 서버는 확인 시각을 주지 않아 다시 열면 nil
    var acknowledgedAt: Date?
}

/// 10-6 아래 연결 문서 (06 문서함)
struct NoticeLinkedDocument: Equatable, Sendable {
    let id: Int
    let title: String
    let category: LibraryCategory
}
