import Foundation

/// 재무 요약 설정의 풀 하나 — GET /admin/finance/settings `pools[]`
/// `{ id: "operation", label: "운영풀", amount, ratio, color, note }`
struct FinanceSettingsPool: Equatable, Identifiable, Sendable {
    let id: String
    var label: String
    /// 지금 쌓인 금액 (원)
    var amount: Int
    /// 새 수금이 들어올 때 나눌 비율 (%)
    var ratio: Int
    /// 웹에서 쓰는 색 · 설명 — 앱은 고치지 않고 그대로 돌려보내요.
    let color: String?
    let note: String?

    /// 서버 `_default_pools()` — 아직 설정이 없을 때
    static let defaults: [FinanceSettingsPool] = [
        FinanceSettingsPool(id: "operation", label: "운영풀", amount: 0, ratio: 60, color: "#3182f6", note: "운영 자금"),
        FinanceSettingsPool(id: "reserve", label: "적립풀", amount: 0, ratio: 30, color: "#7c5cff", note: "예비 자금"),
        FinanceSettingsPool(id: "dividend", label: "배당풀", amount: 0, ratio: 10, color: "#ff8a3d", note: "참여자 배당")
    ]
}
