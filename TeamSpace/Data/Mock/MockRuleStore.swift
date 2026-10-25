import Foundation

/// Mock 규칙 · 제도 — Figma 09 예시 (날짜는 오늘 기준). 읽음 확인을 메모리에 기억해요.
/// 규칙 ID 는 06 문서함의 RULE 문서 ID 와 같아서 문서함에서 눌러도 같은 규칙이 열려요.
final class MockRuleStore: @unchecked Sendable {
    private let lock = NSLock()
    private let now: Date
    private var rules: [RuleSummaryDTO] = []
    private var acknowledgedAt: [Int: Date] = [:]

    init(now: Date = Date()) {
        self.now = now
        rules = [
            rule(1, "프로젝트 운영 원칙", .project, "NativeOps", "v1.3", .scheduled, effective: -5, revised: 4,
                 important: true, change: "검토 기한 3주 → 2주", revisions: 3),
            rule(5, "회의와 의사결정 원칙", .operation, "NativeOps", "v1.1", .active, effective: 3, revised: 7, revisions: 2),
            rule(8, "신규 멤버 온보딩 규칙", .people, "NativeOps", "v1.0", .active, effective: 45, revised: 52, revisions: 1),
            rule(13, "예산 신청·증빙 가이드", .finance, "FA", "v1.0", .active, effective: 14, revised: 20, revisions: 1),
            rule(12, "보안 · 계정 관리 규칙", .operation, "NativeOps", "v1.0", .active, effective: 60, revised: 65, revisions: 1)
        ]
    }

    /// effective · revised: 며칠 전 (음수면 앞으로)
    private func rule(
        _ id: Int, _ title: String, _ category: RuleCategory, _ department: String, _ version: String, _ status: RuleStatus,
        effective: Double, revised: Double, important: Bool = false, change: String? = nil, revisions: Int
    ) -> RuleSummaryDTO {
        RuleSummaryDTO(
            id: id, title: title, category: category, department: department, version: version, status: status,
            effectiveAt: now.addingTimeInterval(-effective * 86_400), revisedAt: now.addingTimeInterval(-revised * 86_400),
            isImportant: important, isAcknowledged: false, changeSummary: change, revisionCount: revisions
        )
    }

    func listJSON() -> String {
        lock.lock()
        defer { lock.unlock() }
        return envelope(RuleListResponseDTO(list: rules))
    }

    func detailJSON(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let rule = rules.first(where: { $0.id == id }) else { return nil }
        return envelope(RuleDetailDTO(
            rule: rule, articles: articles(for: rule), acknowledgedAt: acknowledgedAt[id], revisions: revisions(for: rule)
        ))
    }

    func acknowledge(id: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return nil }
        let date = acknowledgedAt[id] ?? Date()
        acknowledgedAt[id] = date
        rules[index].isAcknowledged = true
        return envelope(RuleAcknowledgeResponseDTO(acknowledgedAt: date))
    }

    private func articles(for rule: RuleSummaryDTO) -> [RuleArticleDTO] {
        guard rule.id == 1 else {
            return [
                RuleArticleDTO(number: 1, title: "목적", body: "\(rule.title)은 팀이 같은 기준으로 일하기 위해 만들어졌어요.",
                               isRevised: false, changeNote: nil),
                RuleArticleDTO(number: 2, title: "적용 범위", body: "Native 모든 구성원과 진행 중인 프로젝트에 적용돼요.",
                               isRevised: false, changeNote: nil),
                RuleArticleDTO(number: 3, title: "문의", body: "궁금한 점은 \(rule.department)에 문의해 주세요.",
                               isRevised: false, changeNote: nil)
            ]
        }
        return [
            RuleArticleDTO(number: 1, title: "목적",
                           body: "이 원칙은 Native에서 진행하는 모든 프로젝트가 같은 기준으로 시작하고, 같은 방식으로 마무리되도록 하기 위해 만들어졌어요.",
                           isRevised: false, changeNote: nil),
            RuleArticleDTO(number: 2, title: "아이디어 제안",
                           body: "누구나 제안서를 올릴 수 있어요. 제안서는 문서함의 템플릿으로 작성하고, PO가 2주 안에 진행 여부를 결정해요.",
                           isRevised: true, changeNote: "검토 기한 3주 → 2주로 단축",
                           comparison: RuleArticleComparisonDTO(
                               label: "검토 기한 단축",
                               previousBody: "누구나 제안서를 올릴 수 있어요. 제안서는 문서함의 템플릿으로 작성하고, PO가 3주 안에 진행 여부를 결정해요.",
                               highlight: "3주 → 2주",
                               reason: "제안 검토 대기 시간을 줄이고 다음 단계 착수를 빠르게 하기 위해 기한을 단축해요."
                           )),
            RuleArticleDTO(number: 3, title: "팀 구성",
                           body: "PM은 프로젝트 시작 전 필요한 직군과 인원을 결재로 요청해요. 인력 지원 요청은 PMO가 1차로 검토해요.",
                           isRevised: false, changeNote: nil),
            RuleArticleDTO(number: 4, title: "출시와 회고",
                           body: "출시 후 2주 안에 회고를 진행하고 결과를 문서함에 남겨요.",
                           isRevised: false, changeNote: nil)
        ]
    }

    /// 09-3 변경 내역 — 프로젝트 운영 원칙은 Figma 내용, 나머지는 버전 수만큼 만들어요.
    private func revisions(for rule: RuleSummaryDTO) -> [RuleRevisionDTO] {
        func daysBefore(_ days: Double) -> Date { rule.revisedAt.addingTimeInterval(-days * 86_400) }
        guard rule.id != 1 else {
            return [
                RuleRevisionDTO(version: "v1.3", revisedAt: rule.revisedAt, summary: "제2조 검토 기한 3주 → 2주",
                                department: rule.department, author: "안율"),
                RuleRevisionDTO(version: "v1.2", revisedAt: daysBefore(70), summary: "제3조 인력 요청을 결재로 일원화",
                                department: rule.department, author: "양지우"),
                RuleRevisionDTO(version: "v1.0", revisedAt: daysBefore(210), summary: "최초 제정",
                                department: "Leader", author: "김민준")
            ]
        }
        let first = RuleRevisionDTO(version: "v1.0", revisedAt: daysBefore(Double(rule.revisionCount - 1) * 60),
                                    summary: "최초 제정", department: "Leader", author: "김민준")
        guard rule.revisionCount > 1 else { return [first] }
        return [
            RuleRevisionDTO(version: rule.version, revisedAt: rule.revisedAt, summary: "제2조 적용 범위 정리",
                            department: rule.department, author: "안율"),
            first
        ]
    }

    private func envelope<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONCoder.makeEncoder().encode(value)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return #"{"code":200,"message":"성공","data":\#(data)}"#
    }
}
