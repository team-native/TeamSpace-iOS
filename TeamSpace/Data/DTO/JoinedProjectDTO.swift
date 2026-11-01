import Foundation

/// GET /workspace/projects 응답의 `data`
/// 명세서에 없는 API 라 Figma 07-6 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct JoinedProjectListResponseDTO: Decodable {
    let list: [JoinedProjectDTO]
}

struct JoinedProjectDTO: Decodable {
    let id: Int
    let name: String
    let summary: String
    let startDate: Date
    let endDate: Date
    let status: ProjectRunStatus

    func toEntity() -> JoinedProject {
        JoinedProject(id: id, name: name, summary: summary, startDate: startDate, endDate: endDate, status: status)
    }
}
