import Foundation
import Observation

/// 09-2 규칙 상세 · 09-4 개정 비교 — 조항별 본문 · 읽음 확인
@Observable
@MainActor
final class RuleDetailViewModel {
    private(set) var state: ViewState<RuleDetail> = .idle
    private(set) var isAcknowledging = false
    var errorMessage: String?

    private let ruleId: Int
    private let fetchRuleDetailUseCase: FetchRuleDetailUseCase
    private let acknowledgeRuleUseCase: AcknowledgeRuleUseCase

    init(ruleId: Int, fetchRuleDetailUseCase: FetchRuleDetailUseCase, acknowledgeRuleUseCase: AcknowledgeRuleUseCase) {
        self.ruleId = ruleId
        self.fetchRuleDetailUseCase = fetchRuleDetailUseCase
        self.acknowledgeRuleUseCase = acknowledgeRuleUseCase
    }

    var detail: RuleDetail? { state.value }

    /// 아래 줄 왼쪽 — "읽어보는 중..." / "10.16 읽음 확인 완료"
    var readingText: String {
        guard let acknowledgedAt = detail?.acknowledgedAt else { return "읽어보는 중..." }
        return "\(TSFormat.shortDate(acknowledgedAt)) 읽음 확인 완료"
    }

    var isAcknowledged: Bool { detail?.acknowledgedAt != nil }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchRuleDetailUseCase.execute(id: ruleId))
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "rule.detail.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    func acknowledge() async {
        guard let detail = detail, !isAcknowledging else { return }
        isAcknowledging = true
        defer { isAcknowledging = false }
        do {
            state = .loaded(try await acknowledgeRuleUseCase.execute(detail))
        } catch {
            AppLog.record(error, context: "rule.acknowledge")
            errorMessage = error.userMessage
        }
    }
}
