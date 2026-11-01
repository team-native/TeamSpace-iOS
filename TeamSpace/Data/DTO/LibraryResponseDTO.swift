import Foundation

/// GET /library 응답의 `data`
/// 명세서에 문서함 API 가 없어 Figma 06-1 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct LibraryResponseDTO: Decodable {
    let list: [LibraryDocumentDTO]
    let latestRevision: LibraryRevisionDTO?

    func toEntity() -> LibraryOverview {
        LibraryOverview(documents: list.map { $0.toEntity() }, latestRevision: latestRevision?.toEntity())
    }
}

/// GET /library/search 응답의 `data` (06-2)
struct LibrarySearchResponseDTO: Decodable {
    let list: [LibraryDocumentDTO]
}

struct LibraryDocumentDTO: Decodable {
    let id: Int
    let category: LibraryCategory
    let title: String
    let summary: String
    let excerpt: String?
    let updatedAt: Date

    func toEntity() -> LibraryDocument {
        LibraryDocument(
            id: id,
            category: category,
            title: title,
            summary: summary,
            excerpt: excerpt,
            updatedAt: updatedAt
        )
    }
}

struct LibraryRevisionDTO: Decodable {
    let documentId: Int
    let title: String
    let effectiveAt: Date

    func toEntity() -> LibraryRevision {
        LibraryRevision(documentId: documentId, title: title, effectiveAt: effectiveAt)
    }
}
