import Foundation

/// `POST /auth/signup-requests` 요청 바디 (TeamSpace-backend `SignupRequest`)
struct AccountRequestRequestDTO: Codable {
    let email: String
    let name: String
    let dept: String
    let password: String
    /// 선택 항목 — nil 이면 바디에서 빠져요.
    var major: String?
    var cohort: String?
    var message: String?
}

/// `POST /auth/signup-requests` 응답 — `{ "id": "12", "status": "PENDING" }`
struct AccountRequestResponseDTO: Decodable {
    let id: Int
    let status: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIntOrString(forKey: .id)
        status = try container.decode(String.self, forKey: .status)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case status
    }

    /// 서버는 접수 번호와 상태만 줘요. 완료 화면에 보여줄 이름 · 이메일 · 부서는 보낸 값으로 채워요.
    func toEntity(form: AccountRequestForm, department: Department, requestedAt: Date = Date()) -> AccountRequestReceipt {
        AccountRequestReceipt(
            name: form.name,
            email: form.email,
            department: department,
            status: AccountRequestStatus(serverValue: status),
            requestedAt: requestedAt
        )
    }
}
