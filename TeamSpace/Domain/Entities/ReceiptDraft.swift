import Foundation

/// 수금 상태 — 서버 문자열 그대로 보내요.
enum ReceiptStatus: String, CaseIterable, Identifiable, Sendable {
    case pending = "입금 대기"
    case billed = "청구 완료"
    case collected = "입금 완료"
    case overdue = "연체"

    var id: String { rawValue }
}

/// 수금 등록 · 수정 [FA · Admin] — POST /admin/finance/receipts · PATCH /admin/finance/receipts/{id}
struct ReceiptDraft: Equatable, Sendable {
    var client = ""
    var project = ""
    /// 원 단위 숫자만 (예: "3600000")
    var amountText = ""
    var status: ReceiptStatus = .pending
    var date = Date()

    var amount: Int? {
        Int(amountText.filter(\.isNumber))
    }

    var isValid: Bool {
        !client.trimmingCharacters(in: .whitespaces).isEmpty
            && !project.trimmingCharacters(in: .whitespaces).isEmpty
            && (amount ?? 0) > 0
    }

    /// "2026-11-04"
    func dayText(calendar: Calendar = .current) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
    }
}

extension ReceiptDraft {
    /// 수금 내역 한 줄로 채워요. 앱은 입금 완료 · 대기만 알아서, 상태를 바꾸지 않으면 보내지 않아요.
    init(_ contract: FinanceContract) {
        client = contract.name
        project = contract.title
        amountText = String(contract.amount)
        status = contract.status == .collected ? .collected : .pending
        date = contract.collectedAt
    }
}
