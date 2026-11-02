import Foundation

/// 재무 저장소 — TeamSpace-backend `/finance/summary` · `/finance/receipts` · `/finance/contracts/{project}`
/// 요약(`/finance/summary`)은 모든 멤버가, 수금 · 계약은 재정 권한(Admin · FA · Leader)만 볼 수 있어요. (없으면 403)
final class FinanceRepositoryImpl: FinanceRepository, @unchecked Sendable {
    private let client: APIClient
    private let calendar: Calendar

    init(client: APIClient, calendar: Calendar = .current) {
        self.client = client
        self.calendar = calendar
    }

    func fetchOverview(month: Date) async throws -> FinanceOverview {
        try await fetchSummary(month: month).toOverview(month: month, calendar: calendar)
    }

    func fetchPublicLedger(year: Int) async throws -> ContractLedger {
        try await fetchSummary().toPublicLedger(year: year)
    }

    /// 서버 `flow` 에 없는 달은 0원으로 채워요.
    func fetchMonthlyFlows(endingAt month: Date, count: Int) async throws -> [MonthlyFlow] {
        let flows = try await fetchSummary().monthlyFlows(calendar: calendar)
        let end = calendar.startOfMonth(for: month)
        return (0..<count).compactMap { index in
            guard let target = calendar.date(byAdding: .month, value: index - (count - 1), to: end) else { return nil }
            return flows.first { calendar.isDate($0.month, equalTo: target, toGranularity: .month) }
                ?? MonthlyFlow(month: target, income: 0, expense: 0)
        }
    }

    /// 수금 내역을 프로젝트별로 묶어요. 모두 입금 완료면 완료.
    func fetchProjectAmounts(year: Int) async throws -> ProjectAmountSummary {
        let receipts = try await fetchReceipts(year: year).items
        var order: [String] = []
        var groups: [String: [ServerReceiptDTO]] = [:]
        for receipt in receipts.sorted(by: { $0.date > $1.date }) {
            if groups[receipt.project] == nil { order.append(receipt.project) }
            groups[receipt.project, default: []].append(receipt)
        }
        let projects = order.enumerated().map { index, name in
            let rows = groups[name] ?? []
            return ProjectAmount(
                id: index + 1,
                name: name,
                status: rows.allSatisfy(\.isCollected) ? .completed : .inProgress,
                contractAmount: rows.reduce(0) { $0 + $1.amount },
                paidAmount: rows.filter(\.isCollected).reduce(0) { $0 + $1.amount }
            )
        }
        let now = Date()
        let thisMonth: (ServerReceiptDTO) -> Bool = { receipt in
            receipt.day.map { self.calendar.isDate($0, equalTo: now, toGranularity: .month) } == true
        }
        let newProjects = order.filter { name in
            let first = (groups[name] ?? []).compactMap(\.day).min()
            return first.map { calendar.isDate($0, equalTo: now, toGranularity: .month) } == true
        }
        return ProjectAmountSummary(
            year: year,
            yearCount: projects.count,
            totalContractAmount: projects.reduce(0) { $0 + ($1.contractAmount ?? 0) },
            totalPaidAmount: projects.reduce(0) { $0 + ($1.paidAmount ?? 0) },
            monthNewContracts: newProjects.count,
            monthDeposits: receipts.filter { $0.isCollected && thisMonth($0) }.count,
            projects: projects
        )
    }

    func fetchContracts(year: Int) async throws -> ContractLedger {
        let page = try await fetchReceipts(year: year)
        let contracts = page.items.compactMap { $0.toEntity() }
        return ContractLedger(
            year: year,
            totalAmount: page.totals?.totalOrder ?? contracts.reduce(0) { $0 + $1.amount },
            contracts: contracts
        )
    }

    /// 수금 한 건을 찾고, 그 프로젝트의 계약 정보를 붙여요. 계약 정보가 없으면 수금 내용만 보여줘요.
    func fetchContract(id: Int) async throws -> ContractDetail {
        guard
            let row = try await fetchReceipts(year: nil).items.first(where: { $0.id == id }),
            let receipt = row.toEntity()
        else { throw AppError.notFound("수주 정보를 찾을 수 없어요") }
        // 프로젝트 이름(공백 · 한글)은 APIClient 가 경로를 인코딩해요.
        let project = row.project
        let contract: ServerContractDTO?
        do {
            contract = try await request(Endpoint(method: .get, path: "finance/contracts/\(project)"), as: ServerContractDTO.self)
        } catch AppError.notFound {
            contract = nil
        }
        return ContractDetail(receipt: receipt, contract: contract)
    }

    /// `month` 를 주면 `month=YYYY-MM` — 그 달 수입 · 지출을 서버가 계산해요.
    private func fetchSummary(month: Date? = nil) async throws -> ServerFinanceSummaryDTO {
        var query: [URLQueryItem] = []
        if let month {
            let parts = calendar.dateComponents([.year, .month], from: month)
            query.append(URLQueryItem(name: "month", value: String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)))
        }
        return try await request(Endpoint(method: .get, path: "finance/summary", queryItems: query), as: ServerFinanceSummaryDTO.self)
    }

    /// GET /finance/receipts?from=YYYY-01-01&to=YYYY-12-31 — 100건씩, 최대 5페이지. 합계는 첫 페이지 값.
    private func fetchReceipts(year: Int?) async throws -> (items: [ServerReceiptDTO], totals: ServerReceiptPageDTO.Totals?) {
        var items: [ServerReceiptDTO] = []
        var totals: ServerReceiptPageDTO.Totals?
        var cursor: String?
        for _ in 0..<5 {
            var query = [URLQueryItem(name: "limit", value: "100")]
            if let year {
                query.append(URLQueryItem(name: "from", value: String(format: "%04d-01-01", year)))
                query.append(URLQueryItem(name: "to", value: String(format: "%04d-12-31", year)))
            }
            if let cursor { query.append(URLQueryItem(name: "cursor", value: cursor)) }
            let page = try await request(Endpoint(method: .get, path: "finance/receipts", queryItems: query), as: ServerReceiptPageDTO.self)
            items += page.items
            totals = totals ?? page.totals
            guard let next = page.nextCursor else { break }
            cursor = next
        }
        return (items, totals)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
