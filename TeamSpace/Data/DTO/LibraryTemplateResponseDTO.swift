import Foundation

/// 06-3 임시 응답 계약. 실제 API 확정 시 Data 레이어에서 조율합니다.
struct LibraryTemplateResponseDTO: Decodable {
    struct FieldDTO: Decodable {
        let title: String
        let subtitle: String
    }

    let id: Int
    let title: String
    let description: String
    let fields: [FieldDTO]
    let monthlyUsageCount: Int
    let formKind: TemplateFormKind

    func toEntity() -> LibraryTemplate {
        LibraryTemplate(
            id: id,
            title: title,
            description: description,
            fields: fields.map { TemplateField(title: $0.title, subtitle: $0.subtitle) },
            monthlyUsageCount: monthlyUsageCount,
            formKind: formKind
        )
    }
}
