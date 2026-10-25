import Foundation

/// GET /users 응답의 `data` · 조직도 안 구성원
/// 명세서에 응답 예시가 없어 Figma 03 팀원 화면 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct MemberListResponseDTO: Decodable {
    let list: [MemberResponseDTO]
}

struct MemberResponseDTO: Decodable {
    let id: Int
    let name: String
    let department: Department
    let roles: [UserRole]
    let tag: String
    let position: String
    let joinedAt: Date

    func toEntity() -> Member {
        Member(
            id: id,
            name: name,
            department: department,
            roles: roles,
            tag: tag,
            position: position,
            joinedAt: joinedAt
        )
    }
}

/// GET /users/{userId} 응답의 `data`
struct MemberDetailResponseDTO: Decodable {
    let id: Int
    let name: String
    let department: Department
    let roles: [UserRole]
    let tag: String
    let position: String
    let joinedAt: Date
    let email: String
    let responsibility: String
    let generation: Int
    let statusMessage: String?
    let projects: [MemberProjectDTO]
    let interests: [String]

    func toEntity() -> MemberDetail {
        MemberDetail(
            member: Member(
                id: id,
                name: name,
                department: department,
                roles: roles,
                tag: tag,
                position: position,
                joinedAt: joinedAt
            ),
            email: email,
            responsibility: responsibility,
            generation: generation,
            statusMessage: statusMessage,
            projects: projects.map { $0.toEntity() },
            interests: interests
        )
    }
}

struct MemberProjectDTO: Decodable {
    let id: Int
    let name: String
    let summary: String
    let role: String
    let status: MemberProject.Status

    func toEntity() -> MemberProject {
        MemberProject(id: id, name: name, summary: summary, role: role, status: status)
    }
}

/// GET /organization/tree 응답의 `data`
struct OrganizationTreeResponseDTO: Decodable {
    let leader: MemberResponseDTO
    let units: [OrganizationUnitDTO]

    func toEntity() -> OrganizationTree {
        OrganizationTree(leader: leader.toEntity(), units: units.map { $0.toEntity() })
    }
}

struct OrganizationUnitDTO: Decodable {
    let id: Int
    let name: String
    let summary: String
    let department: Department
    let members: [MemberResponseDTO]

    func toEntity() -> OrganizationUnit {
        OrganizationUnit(
            id: id,
            name: name,
            summary: summary,
            department: department,
            members: members.map { $0.toEntity() }
        )
    }
}
