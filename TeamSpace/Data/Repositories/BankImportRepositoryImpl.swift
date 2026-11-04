import Foundation

final class BankImportRepositoryImpl: BankImportRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchImports() async throws -> [BankImport] {
        try await request(
            Endpoint(method: .get, path: "finance/bank-imports", queryItems: [URLQueryItem(name: "limit", value: "100")]),
            as: CursorPageDTO<ServerBankImportDTO>.self
        ).items.compactMap { $0.toEntity() }
    }

    func review(id: String, confirm: Bool, exclude: Bool, matchedProject: String?) async throws -> (status: BankImport.Status, matchedProject: String?) {
        let dto = try await request(
            Endpoint(
                method: .patch,
                path: "finance/bank-imports/\(id)",
                body: ServerBankImportReviewRequestDTO(matchedProject: matchedProject, confirm: confirm, exclude: exclude)
            ),
            as: ServerBankImportReviewDTO.self
        )
        guard let status = BankImport.Status(rawValue: dto.status) else { throw AppError.decoding("은행 거래 상태를 읽지 못했어요.") }
        return (status, dto.matchedProject)
    }

    func fetchAccount() async throws -> BankAccountStatus {
        try await request(Endpoint(method: .get, path: "finance/bank-accounts"), as: ServerBankAccountDTO.self).toEntity()
    }

    func sync() async throws -> BankSyncResult {
        let dto: ServerBankSyncDTO
        do {
            dto = try await client.request(Endpoint(method: .post, path: "finance/bank-syncs"), as: ServerBankSyncDTO.self)
        } catch NetworkError.status(let code, let body) where code == 502 || code == 503 {
            // 은행 쪽 실패는 서버가 사유를 알려줘요. (`detail.message`)
            throw AppError.conflict(body?.message ?? "은행 거래를 불러오지 못했어요.")
        } catch let error as NetworkError {
            throw error.asAppError
        }
        return BankSyncResult(
            fetchedCount: dto.fetchedCount,
            importedCount: dto.importedCount,
            lastSyncedAt: dto.lastSyncedAt.flatMap(ServerDate.parse)
        )
    }

    func commit(rowIds: [String]) async throws -> BankImportCommitResult {
        let dto = try await request(
            Endpoint(method: .post, path: "finance/bank-import-commits", body: ServerBankImportCommitRequestDTO(rowIds: rowIds)),
            as: ServerBankImportCommitDTO.self
        )
        return BankImportCommitResult(committedCount: dto.committedCount, receiptCount: dto.receiptCount, expenseCount: dto.expenseCount)
    }

    private func request<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        do {
            return try await client.request(endpoint, as: type)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}
