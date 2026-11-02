import Foundation

enum TemplateFormKind: String, UnknownCaseDecodable, Hashable, Sendable {
    case expense = "EXPENSE"
    case staffing = "STAFFING"
    case settlement = "SETTLEMENT"
    case unknown = "UNKNOWN"

    static let unknownCase: TemplateFormKind = .unknown
}

struct TemplateField: Equatable, Sendable {
    let title: String
    let subtitle: String
}

/// 06-3 템플릿 설명과 연결할 결재 양식
struct LibraryTemplate: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let fields: [TemplateField]
    /// 서버에 없어 0이면 숨겨요.
    let monthlyUsageCount: Int
    let formKind: TemplateFormKind
}
