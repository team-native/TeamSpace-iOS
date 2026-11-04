import Foundation

/// GET /finance/summary (TeamSpace-backend `workflows.finance_summary`, 프런트 `InhouseData`)
/// `month=YYYY-MM` 을 보내면 그 달 기준으로 계산하고, 없으면 이번 달이에요. 지난 달은 `flow` 로도 알 수 있어요.
/// 재정 권한이 없으면 `receipts` 가 빠져서 와요.
struct ServerFinanceSummaryDTO: Decodable {
    let period: String?
    /// 서버가 계산한 달 "2026-10"
    let month: String?
    let demo: Bool
    let lastSyncedAt: Date?
    let summary: Numbers
    let pools: [ServerFinancePoolDTO]
    let flow: [ServerFinanceFlowDTO]
    let receipts: [ServerReceiptDTO]

    struct Numbers: Decodable {
        let available: Int
        let monthlyRevenue: Int
        let monthlyExpense: Int
        let externalReceipts: Int
        let reserveBalance: Int

        private enum CodingKeys: String, CodingKey {
            case available, monthlyRevenue, monthlyExpense, externalReceipts, reserveBalance
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            available = container.money(.available)
            monthlyRevenue = container.money(.monthlyRevenue)
            monthlyExpense = container.money(.monthlyExpense)
            externalReceipts = container.money(.externalReceipts)
            reserveBalance = container.money(.reserveBalance)
        }
    }

    private enum CodingKeys: String, CodingKey { case period, month, demo, lastSyncedAt, summary, pools, flow, receipts }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = try? container.decodeIfPresent(String.self, forKey: .period)
        month = try? container.decodeIfPresent(String.self, forKey: .month)
        demo = (try? container.decodeIfPresent(Bool.self, forKey: .demo)) ?? false
        lastSyncedAt = (try? container.decodeIfPresent(String.self, forKey: .lastSyncedAt)).flatMap { ServerDate.parse($0) }
        summary = try container.decode(Numbers.self, forKey: .summary)
        pools = (try? container.decodeIfPresent([ServerFinancePoolDTO].self, forKey: .pools)) ?? []
        flow = (try? container.decodeIfPresent([ServerFinanceFlowDTO].self, forKey: .flow)) ?? []
        receipts = (try? container.decodeIfPresent([ServerReceiptDTO].self, forKey: .receipts)) ?? []
    }

    /// 04-1 — 이번 달이 아니면 `flow` 의 그 달 수입 · 지출로 바꿔 보여줘요.
    func toOverview(month: Date, now: Date = Date(), calendar: Calendar = .current) -> FinanceOverview {
        // 서버가 그 달로 계산해 줬으면 summary 를, 아니면 flow 의 그 달 값을 써요.
        let serverMonth = self.month.flatMap { ServerFinanceFlowDTO.monthDate($0, calendar: calendar) }
        let isCurrent = serverMonth.map { calendar.isDate($0, equalTo: month, toGranularity: .month) }
            ?? calendar.isDate(month, equalTo: now, toGranularity: .month)
        let flows = monthlyFlows(calendar: calendar)
        let selected = flows.first { calendar.isDate($0.month, equalTo: month, toGranularity: .month) }
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: month) ?? month
        let previous = flows.first { calendar.isDate($0.month, equalTo: previousMonth, toGranularity: .month) }
        let income = isCurrent ? summary.monthlyRevenue : (selected?.income ?? 0)
        let expense = isCurrent ? summary.monthlyExpense : (selected?.expense ?? 0)
        let collectedCount = receipts.filter {
            $0.isCollected && $0.day.map { calendar.isDate($0, equalTo: month, toGranularity: .month) } == true
        }.count
        let changeRate: Double = {
            guard let previous, previous.income > 0 else { return 0 }
            return (Double(income - previous.income) / Double(previous.income) * 1000).rounded() / 10
        }()
        return FinanceOverview(
            month: month,
            collectedAmount: income,
            isDemo: demo,
            pools: pools.map { $0.toEntity() },
            availableAmount: summary.available,
            changeRate: changeRate,
            income: FinanceFlow(amount: income, note: collectedCount > 0 ? "외주 수금 \(collectedCount)건" : "외주 수금"),
            expense: FinanceFlow(amount: expense, note: "승인된 지출 · 은행 출금"),
            updatedAt: lastSyncedAt ?? now
        )
    }

    func monthlyFlows(calendar: Calendar = .current) -> [MonthlyFlow] {
        flow.compactMap { item in
            item.monthDate(calendar: calendar).map { MonthlyFlow(month: $0, income: item.income, expense: item.expense) }
        }
    }
}

/// 풀 — 프런트 `Pool { id: operation|reserve|dividend, label, amount, ratio, color, note }`
struct ServerFinancePoolDTO: Decodable {
    let id: String
    let amount: Int
    let ratio: Int

    private enum CodingKeys: String, CodingKey { case id, amount, ratio }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        amount = container.money(.amount)
        ratio = container.money(.ratio)
    }

    func toEntity() -> FinancePool {
        FinancePool(kind: FinancePoolKind(rawValue: id.uppercased()) ?? .unknown, ratio: ratio, amount: amount, count: nil)
    }
}

/// 월별 흐름 `{ month: "2026-10", income, expense }`
struct ServerFinanceFlowDTO: Decodable {
    let month: String
    let income: Int
    let expense: Int

    private enum CodingKeys: String, CodingKey { case month, income, expense }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        month = (try? container.decodeIfPresent(String.self, forKey: .month)) ?? ""
        income = container.money(.income)
        expense = container.money(.expense)
    }

    func monthDate(calendar: Calendar) -> Date? {
        Self.monthDate(month, calendar: calendar)
    }

    /// "2026-10" → 10월 1일
    static func monthDate(_ month: String, calendar: Calendar) -> Date? {
        let parts = month.prefix(7).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: 1))
    }
}

/// 수금 한 건 — `{ id, client, project, amount, status, date }` (status: 입금 완료 · 입금 대기 · 청구 완료 · 연체)
struct ServerReceiptDTO: Decodable {
    let id: Int?
    let client: String
    let project: String
    let amount: Int
    let status: String
    let date: String

    private enum CodingKeys: String, CodingKey { case id, client, project, amount, status, date }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIntOrString(forKey: .id)
        client = (try? container.decodeIfPresent(String.self, forKey: .client)) ?? ""
        project = (try? container.decodeIfPresent(String.self, forKey: .project)) ?? ""
        amount = container.money(.amount)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        date = (try? container.decodeIfPresent(String.self, forKey: .date)) ?? ""
    }

    var isCollected: Bool { status == "입금 완료" }
    var day: Date? { ServerTodoDTO.date(fromDay: String(date.prefix(10))) }

    func toEntity() -> FinanceContract? {
        guard let id, let day else { return nil }
        return FinanceContract(
            id: id, name: client, title: project, amount: amount, collectedAt: day,
            status: isCollected ? .collected : .scheduled
        )
    }
}

extension ServerFinanceSummaryDTO {
    /// 04-7 구성원 공개 요약 — 수금 내역을 볼 수 없어 누적 수주 합계만 보여줘요.
    func toPublicLedger(year: Int) -> ContractLedger {
        ContractLedger(year: year, totalAmount: summary.externalReceipts, contracts: [])
    }
}

/// GET /finance/receipts — 목록 + 상태별 합계
struct ServerReceiptPageDTO: Decodable {
    let items: [ServerReceiptDTO]
    let nextCursor: String?
    let totals: Totals?

    struct Totals: Decodable {
        let totalOrder: Int
        let paid: Int
        let pending: Int
        let overdue: Int

        private enum CodingKeys: String, CodingKey { case totalOrder, paid, pending, overdue }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            totalOrder = container.money(.totalOrder)
            paid = container.money(.paid)
            pending = container.money(.pending)
            overdue = container.money(.overdue)
        }
    }
}

/// GET /finance/contracts/{project} — 프런트 `CONTRACTS[project]`
/// `{ pm, signed, total, collected, step, stepDates, staff, split, next, file }`
struct ServerContractDTO: Decodable {
    /// 프런트 `CONTRACT_STEPS`
    static let stepTitles = ["상담", "견적", "계약", "제작", "납품", "수금"]

    let pm: String?
    let signed: String?
    let total: Int?
    let collected: Int?
    let step: Int
    let stepDates: [String]
    let staff: String?
    let split: String?
    let next: String?
    let file: String?

    private enum CodingKeys: String, CodingKey { case pm, signed, total, collected, step, stepDates, staff, split, next, file }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pm = try? container.decodeIfPresent(String.self, forKey: .pm)
        signed = try? container.decodeIfPresent(String.self, forKey: .signed)
        total = container.contains(.total) ? container.money(.total) : nil
        collected = container.contains(.collected) ? container.money(.collected) : nil
        step = container.money(.step)
        stepDates = (try? container.decodeIfPresent([String].self, forKey: .stepDates)) ?? []
        staff = try? container.decodeIfPresent(String.self, forKey: .staff)
        split = try? container.decodeIfPresent(String.self, forKey: .split)
        next = try? container.decodeIfPresent(String.self, forKey: .next)
        file = try? container.decodeIfPresent(String.self, forKey: .file)
    }

    /// "2026.08.04" 의 연도
    var signedYear: Int? { signed.flatMap { Int($0.prefix(4)) } }

    func steps(calendar: Calendar = .current) -> [ContractStep] {
        Self.stepTitles.enumerated().map { index, title in
            let text = index < stepDates.count ? stepDates[index] : ""
            let date = Self.monthDay(text, year: signedYear, calendar: calendar)
            let note = date == nil ? (text == "—" ? "" : text) : (text.count > 5 ? String(text.dropFirst(5)).trimmingCharacters(in: .whitespaces) : "")
            return ContractStep(id: index + 1, title: title, date: date, note: note, isDone: index < step)
        }
    }

    /// "08.01" · "11.20 예정" → 그해 그날
    static func monthDay(_ text: String, year: Int?, calendar: Calendar) -> Date? {
        let parts = text.prefix(5).split(separator: ".").compactMap { Int($0) }
        guard parts.count == 2, let year else { return nil }
        return calendar.date(from: DateComponents(year: year, month: parts[0], day: parts[1]))
    }

    /// "운영 60% · 적립 30% · 배당 10%" → 계약 금액을 비율대로 나눠요.
    func pools(total amount: Int) -> [FinancePool] {
        (split ?? "").components(separatedBy: "·").compactMap { part in
            let text = part.trimmingCharacters(in: .whitespaces)
            guard let ratio = Int(text.filter(\.isNumber)) else { return nil }
            let kind: FinancePoolKind = text.hasPrefix("운영") ? .operation : text.hasPrefix("적립") ? .reserve : text.hasPrefix("배당") ? .dividend : .unknown
            return FinancePool(kind: kind, ratio: ratio, amount: amount * ratio / 100, count: nil)
        }
    }

    /// "iOS 2 · Design 1 · Backend 1" → 4명
    var memberCount: Int {
        (staff ?? "").components(separatedBy: "·").reduce(0) { sum, part in
            sum + (Int(part.filter(\.isNumber)) ?? 0)
        }
    }

    /// "박도윤 · PMO" → "박도윤"
    var managerName: String {
        (pm ?? "").components(separatedBy: " · ").first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
}

extension ContractDetail {
    /// 수금 한 건 + 계약 정보(없으면 수금 내용만)
    init(receipt: FinanceContract, contract: ServerContractDTO?) {
        let total = contract?.total ?? receipt.amount
        let collected = receipt.status == .collected ? "입금 확인" : "입금 예정"
        self.init(
            contract: receipt,
            category: "외주",
            clientName: "클라이언트 \(receipt.name)",
            amountNote: [collected, contract?.next].compactMap { $0 }.joined(separator: " · "),
            steps: contract?.steps() ?? [],
            pools: contract?.pools(total: total) ?? [],
            managerName: contract?.managerName ?? "",
            memberCount: contract?.memberCount ?? 0,
            documentName: contract?.file,
            info: contract.map {
                ContractInfo(
                    pm: $0.pm, signed: $0.signed, total: $0.total, collected: $0.collected,
                    step: $0.step, staff: $0.staff, split: $0.split, next: $0.next
                )
            }
        )
    }
}

extension KeyedDecodingContainer {
    /// 금액이 숫자 · 문자열("1500000") · 소수 어느 쪽으로 와도 정수로 읽어요. 없으면 0.
    func money(_ key: Key) -> Int {
        if let number = try? decode(Int.self, forKey: key) { return number }
        if let number = try? decode(Double.self, forKey: key) { return Int(number) }
        if let text = try? decode(String.self, forKey: key) { return Int(text.filter(\.isNumber)) ?? 0 }
        return 0
    }
}

/// 월 파라미터 (yyyy-MM) — 일정 `GET /events?month=` 에서도 써요.
enum FinanceMonthParameter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter.date(from: string)
    }
}

/// POST /admin/finance/receipts · PATCH /admin/finance/receipts/{id} 요청 — 비운 값은 보내지 않아요.
/// 등록은 client · project · amount · status · date 가 모두 필요해요.
struct ServerReceiptWriteRequestDTO: Codable, Equatable {
    var client: String?
    var project: String?
    var amount: Int?
    var status: String?
    var date: String?
}
