import Foundation

/// POST /documents 요청 바디
struct DocumentCreateRequestDTO: Codable {
    let type: String
    let title: String
    let amount: Int?
    let fields: [DocumentFieldRequestDTO]
    let reason: String
    let attachments: [String]

    init(_ draft: DocumentDraft) {
        type = draft.kind.rawValue
        title = draft.title
        amount = draft.amount
        fields = draft.fields.map { DocumentFieldRequestDTO(title: $0.title, value: $0.value) }
        reason = draft.reason
        attachments = draft.attachmentNames
    }
}

struct DocumentFieldRequestDTO: Codable {
    let title: String
    let value: String
}

/// POST /documents 응답의 `data`
struct DocumentCreateResponseDTO: Decodable {
    let documentId: Int
}
