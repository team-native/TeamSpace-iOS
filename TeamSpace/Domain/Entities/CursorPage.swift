import Foundation

/// COMMON-02 목록 한 페이지 — 서버 응답 `{ items, nextCursor }`
/// `nextCursor` 가 nil 이면 마지막 페이지예요.
struct CursorPage<Item: Sendable>: Sendable {
    let items: [Item]
    let nextCursor: String?

    var hasMore: Bool { nextCursor != nil }
}

extension CursorPage: Equatable where Item: Equatable {}
