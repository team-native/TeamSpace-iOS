import Foundation

struct FetchContractDetailUseCase {
    private let financeRepository: FinanceRepository

    init(financeRepository: FinanceRepository) {
        self.financeRepository = financeRepository
    }

    func execute(id: Int) async throws -> ContractDetail {
        try await financeRepository.fetchContract(id: id)
    }
}
