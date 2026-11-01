import Foundation

/// 01-2 인하우스 계정 요청 입력값
struct AccountRequestForm: Equatable {
    var name: String = ""
    var email: String = ""
    var department: Department?
    var password: String = ""

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var isEmailValid: Bool {
        let parts = email.trimmingCharacters(in: .whitespaces).split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }

    /// 영문 · 숫자 포함 8자 이상
    var isPasswordValid: Bool {
        let hasLetter = password.contains { $0.isLetter }
        let hasNumber = password.contains { $0.isNumber }
        return password.count >= 8 && hasLetter && hasNumber
    }

    var isSubmittable: Bool {
        !trimmedName.isEmpty && isEmailValid && department != nil && isPasswordValid
    }
}

enum AccountRequestStatus: String, UnknownCaseDecodable {
    case reviewing = "REVIEWING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case unknown = "UNKNOWN"

    static let unknownCase: AccountRequestStatus = .unknown
}

/// 01-3 요청 완료 화면에 보여줄 접수 결과
struct AccountRequestReceipt: Hashable {
    let name: String
    let email: String
    let department: Department
    let status: AccountRequestStatus
    let requestedAt: Date
}
