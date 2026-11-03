import Foundation

/// 12-2c 담당자 처리 — 상태를 바꾸거나 공식 답변 · 반려 사유를 남겨요.
struct ProposalManageDraft: Equatable, Sendable {
    static let bodyLimit = 1_000

    enum Action: CaseIterable, Hashable, Sendable {
        case reviewing
        case inProgress
        case answer
        case reject

        var title: String {
            switch self {
            case .reviewing: return "검토 중"
            case .inProgress: return "진행 중"
            case .answer: return "답변"
            case .reject: return "반려"
            }
        }

        var status: ProposalStatus {
            switch self {
            case .reviewing: return .reviewing
            case .inProgress: return .inProgress
            case .answer: return .answered
            case .reject: return .rejected
            }
        }

        /// 답변 · 반려는 글이 꼭 있어야 해요.
        var needsBody: Bool { self == .answer || self == .reject }
    }

    var action: Action = .reviewing
    var body = ""

    /// 지금 상태에 맞춰 다음 처리를 골라 둬요.
    init(current status: ProposalStatus = .received) {
        switch status {
        case .received: action = .reviewing
        case .reviewing: action = .inProgress
        default: action = .answer
        }
    }
}
