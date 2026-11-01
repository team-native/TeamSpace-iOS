import Foundation

/// 공지 한 건 (목록 · 고정 공지 · 검색 결과)
struct NoticeSummary: Equatable, Identifiable, Sendable {
    let id: Int
    let category: NoticeCategory
    let title: String
    /// 검색 결과에 보이는 한 줄 요약
    let summary: String?
    let updatedAt: Date
    let isPinned: Bool
    let isImportant: Bool
}
