import Foundation
import Observation

/// 04-2 수주 상세
@Observable
@MainActor
final class ContractDetailViewModel {
    private(set) var state: ViewState<ContractDetail> = .idle
    var toastMessage: String?

    let contractId: Int
    private let fetchContractDetailUseCase: FetchContractDetailUseCase

    init(contractId: Int, fetchContractDetailUseCase: FetchContractDetailUseCase) {
        self.contractId = contractId
        self.fetchContractDetailUseCase = fetchContractDetailUseCase
    }

    var shareLink: String {
        "teamspace://finance/contracts/\(contractId)"
    }

    /// "2026.10.18 입금 확인 · 부가세 별도"
    func amountCaption(_ detail: ContractDetail) -> String {
        "\(TSFormat.fullDate(detail.contract.collectedAt)) \(detail.amountNote)"
    }


    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchContractDetailUseCase.execute(id: contractId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "finance.contractDetail")
            if state.value == nil { state = .failed(error) }
        }
    }

    func didCopyLink() {
        toastMessage = "수주 링크를 복사했어요."
    }
}
