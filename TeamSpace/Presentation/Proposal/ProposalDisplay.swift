import Foundation

/// 12-1b 정렬
enum ProposalSort: CaseIterable, Hashable {
    case latest
    case recommended

    var title: String { self == .latest ? "최신순" : "추천순" }
}

/// 12-1b 진행 단계 칩 — 진행중(접수 · 검토 · 진행) / 완료(완료 · 답변 · 채택 · 종료 · 반려)
enum ProposalPhase: CaseIterable, Hashable {
    case ongoing
    case done

    var title: String { self == .ongoing ? "진행중" : "완료" }

    func contains(_ status: ProposalStatus) -> Bool {
        switch status {
        case .received, .reviewing, .inProgress: return self == .ongoing
        case .completed, .answered, .adopted, .closed, .rejected: return self == .done
        case .unknown: return false
        }
    }
}

extension ProposalStatus {
    /// 12-2b 진행 상태 4단계
    static let steps: [ProposalStatus] = [.received, .reviewing, .inProgress, .completed]

    /// 12-2b 단계 이름 — "진행 중"은 단계에서는 "진행"
    var stepTitle: String { self == .inProgress ? "진행" : title }
}

extension ProposalSummary {
    /// "익명 · 10.15" / "이시우 · 10.08"
    var authorDateText: String {
        "\(isAnonymous ? "익명" : authorName ?? "익명") · \(TSFormat.shortDate(createdAt))"
    }

    /// "댓글 7 · 추천 32"
    var countText: String { "댓글 \(commentCount) · 추천 \(recommendCount)" }
}

extension ProposalDetail {
    /// "익명 · 10.15 · 조회 128" — 조회 수가 없으면 빼요.
    var metaText: String {
        viewCount.map { "\(proposal.authorDateText) · 조회 \($0)" } ?? proposal.authorDateText
    }

    /// 12-2b 진행 상태 — 4단계마다 도달한 날짜 (없으면 nil)
    var stepDates: [(status: ProposalStatus, date: Date?)] {
        ProposalStatus.steps.map { status in (status, steps.first { $0.status == status }?.reachedAt) }
    }
}

extension ProposalComment {
    /// "익명 2 · 10.15" / "옥물결 · 제안자 · 10.16"
    var headerText: String {
        let name = isAnonymous ? "익명\(anonymousNumber.map { " \($0)" } ?? "")" : authorName ?? "익명"
        let role = isProposer ? " · 제안자" : ""
        return "\(name)\(role) · \(TSFormat.shortDate(createdAt))"
    }
}
