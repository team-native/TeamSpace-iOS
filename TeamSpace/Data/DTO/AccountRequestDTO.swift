import Foundation

/// 계정 요청 요청 바디. TODO: 백엔드 API 확정 후 필드명 맞추기
struct AccountRequestRequestDTO: Codable {
    let name: String
    let email: String
    let department: String
    let password: String
}

/// 계정 요청 응답의 `data`
struct AccountRequestResponseDTO: Decodable {
    let name: String
    let email: String
    let department: Department
    let status: AccountRequestStatus
    let requestedAt: Date

    func toEntity() -> AccountRequestReceipt {
        AccountRequestReceipt(
            name: name,
            email: email,
            department: department,
            status: status,
            requestedAt: requestedAt
        )
    }
}
