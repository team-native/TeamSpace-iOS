import Foundation

/// 10-6 공지 상세
struct NoticeDetail: Equatable, Sendable {
    let notice: NoticeSummary
    let authorName: String
    /// 예) "FA"
    let authorRole: String
    let body: String
    let viewCount: Int
    /// 본문과 함께 보는 문서함 문서
    let linkedDocument: NoticeLinkedDocument?
    var acknowledgedAt: Date?
}

/// 10-6 아래 연결 문서 (06 문서함)
struct NoticeLinkedDocument: Equatable, Sendable {
    let id: Int
    let title: String
    let category: LibraryCategory
}
