import Foundation

/// 수주 계약 정보 — GET /finance/contracts/{project} (프런트 `CONTRACTS[project]`)
struct ContractInfo: Equatable, Sendable {
    /// 예) 이시우 · PM
    var pm: String?
    /// "2026.09.02"
    var signed: String?
    var total: Int?
    var collected: Int?
    /// 끝난 단계 수 (상담 · 견적 · 계약 · 제작 · 납품 · 수금 → 0 ~ 6)
    var step: Int
    /// 예) iOS 2 · Design 1
    var staff: String?
    /// 예) 운영 60% · 적립 30% · 배당 10%
    var split: String?
    /// 예) 11.20 잔금 예정
    var next: String?
}

/// 계약 정보 등록 · 수정 [FA · Admin] — POST /admin/finance/contracts · PATCH /admin/finance/contracts/{project}
struct ContractInfoDraft: Equatable, Sendable {
    static let stepTitles = ["상담", "견적", "계약", "제작", "납품", "수금"]

    var pm = ""
    var signedDate = Date()
    var totalText = ""
    var collectedText = ""
    var step = 0
    var staff = ""
    var split = "운영 60% · 적립 30% · 배당 10%"
    var next = ""

    var total: Int? { Int(totalText.filter(\.isNumber)) }
    var collected: Int? { Int(collectedText.filter(\.isNumber)) }

    /// "2026.09.02"
    func signedText(calendar: Calendar = .current) -> String {
        let day = calendar.dateComponents([.year, .month, .day], from: signedDate)
        return String(format: "%04d.%02d.%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
    }

    /// "운영 60% · 적립 30% · 배당 10%" 의 비율 합 (비우면 nil)
    var splitTotal: Int? {
        let ratios = split.components(separatedBy: "·").compactMap { Int($0.filter(\.isNumber)) }
        return ratios.isEmpty ? nil : ratios.reduce(0, +)
    }

    /// 다음 단계 이름 — "제작까지 끝났어요"
    var stepText: String {
        step == 0 ? "아직 시작 전이에요" : "\(Self.stepTitles[min(step, Self.stepTitles.count) - 1])까지 끝났어요"
    }
}

extension ContractInfoDraft {
    init(_ info: ContractInfo, calendar: Calendar = .current) {
        pm = info.pm ?? ""
        if let signed = info.signed {
            let parts = signed.split(whereSeparator: { $0 == "." || $0 == "-" }).compactMap { Int($0) }
            if parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) {
                signedDate = date
            }
        }
        totalText = info.total.map(String.init) ?? ""
        collectedText = info.collected.map(String.init) ?? ""
        step = info.step
        staff = info.staff ?? ""
        split = info.split ?? ""
        next = info.next ?? ""
    }
}
