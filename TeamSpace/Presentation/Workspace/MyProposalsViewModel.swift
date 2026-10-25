import Foundation
import Observation

/// 07-11 내가 작성한 운영 제안
@Observable
@MainActor
final class MyProposalsViewModel {
    private(set) var state: ViewState<[MyProposal]> = .idle
    var filter: ProposalFilter = .all
    let userName: String

    private let fetchMyProposalsUseCase: FetchMyProposalsUseCase
    private let now: () -> Date

    init(userName: String, fetchMyProposalsUseCase: FetchMyProposalsUseCase, now: @escaping () -> Date = { Date() }) {
        self.userName = userName
        self.fetchMyProposalsUseCase = fetchMyProposalsUseCase
        self.now = now
    }

    private var all: [MyProposal] { state.value ?? [] }

    var proposals: [MyProposal] {
        guard let status = filter.status else { return all }
        return all.filter { $0.status == status }
    }

    func count(of filter: ProposalFilter) -> Int {
        guard let status = filter.status else { return all.count }
        return all.filter { $0.status == status }.count
    }

    /// "옥물결 님이 작성한 운영 제안 3개"
    var subtitle: String {
        "\(userName) 님이 작성한 운영 제안 \(all.count)개"
    }

    /// "2026.10.16 기준"
    var baseDateText: String {
        "\(TSFormat.fullDate(now())) 기준"
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchMyProposalsUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.proposals.load")
            if state.value == nil { state = .failed(error) }
        }
    }
}
