import SwiftUI

extension ApprovalKind {
    /// 07-4 문서 종류 이름 ("예산 품의서")
    var documentTitle: String {
        switch self {
        case .expense: return "예산 품의서"
        case .staffing: return "인원 지원 요청서"
        case .projectRequest: return "프로젝트 관련 요청서"
        case .operationRequest: return "운영 관련 요청서"
        case .other: return "기타 내부 문서"
        case .unknown: return "문서"
        }
    }

    /// 07-5 이어서 작성할 때 열 결재 올리기 양식
    var composeKind: ApprovalComposeKind {
        switch self {
        case .expense: return .expense
        case .staffing: return .staffing
        case .projectRequest: return .projectRequest
        case .operationRequest: return .operationRequest
        case .other, .unknown: return .etcDocument
        }
    }
}

extension MyDocument {
    /// "예산 품의서 · 제출 2026.10.14" / "인원 지원 요청서 · 작성 중"
    var headerText: String {
        guard let submittedAt else { return "\(kind.documentTitle) · 작성 중" }
        return "\(kind.documentTitle) · 제출 \(TSFormat.fullDate(submittedAt))"
    }

    /// 상태마다 다른 진행 정보 한 줄
    var progressText: String {
        switch status {
        case .draft:
            return "제출일 없음 · 현재 결재자 없음 · \(TSFormat.shortDate(updatedAt)) 자동 저장"
        case .pending, .reviewing:
            let approver = currentApprover.map { "현재 결재자 \($0.name) · \($0.department)" }
            return [amount.map(TSFormat.won), approver, currentStepTitle].compactMap { $0 }.joined(separator: " · ")
        case .approved:
            let decider = decidedBy.map { "최종 결재 \($0.name)" }
            let when = decidedAt.map { "\(TSFormat.shortDate($0)) 승인 완료" }
            return [decider, when, "현재 결재자 없음"].compactMap { $0 }.joined(separator: " · ")
        case .rejected:
            let decider = decidedBy.map { "\($0.name) · \($0.department)" }
            let when = decidedAt.map { "\(TSFormat.shortDate($0)) 반려 사유: \(rejectReason ?? "-")" }
            return [decider, when].compactMap { $0 }.joined(separator: " · ")
        case .unknown:
            return "진행 상황을 확인하고 있어요."
        }
    }

    /// 카드 아래 링크 제목
    var linkTitle: String {
        switch status {
        case .draft: return "임시 저장에서 이어쓰기"
        case .pending: return "제출 문서 보기"
        case .reviewing: return "진행 상황 확인"
        case .approved: return "승인 문서 보기"
        case .rejected: return "반려 사유 확인 · 수정 후 재상신"
        case .unknown: return "문서 보기"
        }
    }

    var linkRoute: AppRoute {
        isDraft ? .workspaceDrafts : .approvalDetail(documentId: id)
    }

    /// 07-5 "인원 지원 요청서 · NativeLab"
    var draftKindText: String {
        [kind.documentTitle, projectName].compactMap { $0 }.joined(separator: " · ")
    }

    /// 검색 — 제목 · 프로젝트
    func matches(_ query: String) -> Bool {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(keyword)
            || (projectName?.localizedCaseInsensitiveContains(keyword) ?? false)
    }
}
