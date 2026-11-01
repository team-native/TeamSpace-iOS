import Foundation

/// GET /workspace/documents 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-4 · 07-5 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct MyDocumentListResponseDTO: Decodable {
    let list: [MyDocumentDTO]
}

struct MyDocumentDTO: Decodable {
    let id: Int
    let kind: ApprovalKind
    let title: String
    let amount: Int?
    let status: ApprovalStatus
    let projectName: String?
    let summary: String?
    let submittedAt: Date?
    let updatedAt: Date
    let currentApproverName: String?
    let currentApproverDepartment: String?
    let currentStepTitle: String?
    let decidedByName: String?
    let decidedByDepartment: String?
    let decidedAt: Date?
    let rejectReason: String?

    func toEntity() -> MyDocument {
        MyDocument(
            id: id,
            kind: kind,
            title: title,
            amount: amount,
            status: status,
            projectName: projectName,
            summary: summary,
            submittedAt: submittedAt,
            updatedAt: updatedAt,
            currentApprover: person(currentApproverName, currentApproverDepartment),
            currentStepTitle: currentStepTitle,
            decidedBy: person(decidedByName, decidedByDepartment),
            decidedAt: decidedAt,
            rejectReason: rejectReason
        )
    }

    private func person(_ name: String?, _ department: String?) -> DocumentPerson? {
        guard let name else { return nil }
        return DocumentPerson(name: name, department: department ?? "")
    }
}
