import Foundation
import Observation

/// 05-11 · 05-12 · 05-13 요청서 종류
enum RequestFormKind: Equatable {
    case project    // 05-12 프로젝트 관련 요청서
    case operation  // 05-13 운영 관련 요청서
    case etc        // 05-11 기타 내부 문서

    var title: String {
        switch self {
        case .project: return "프로젝트 관련 요청서"
        case .operation: return "운영 관련 요청서"
        case .etc: return "기타 내부 문서"
        }
    }

    var subtitle: String {
        switch self {
        case .project: return "프로젝트 PM과 운영 리드가 순서대로 검토해요."
        case .operation: return "NativeOps 검토 후 리더가 최종 승인해요."
        case .etc: return "보고 · 공유할 내용을 자유롭게 적어 주세요."
        }
    }

    var approvalKind: ApprovalKind {
        switch self {
        case .project: return .projectRequest
        case .operation: return .operationRequest
        case .etc: return .other
        }
    }

    /// 요청 종류 · 분류 칩
    var categories: [String] {
        switch self {
        case .project: return ["인원 조정", "일정 변경", "예산", "기타"]
        case .operation: return ["물품 · 시설", "행사", "예산", "규정 · 기타"]
        case .etc: return []
        }
    }

    /// 결재선 — 조회 API 가 생기면 서버 값으로 바꿔요. (Figma 05-11 · 05-12 · 05-13)
    var approvalLine: [(name: String, role: String)] {
        switch self {
        case .project: return [("이시우", "PM · Book-on"), ("양지우", "NativeOps"), ("김민준", "Leader")]
        case .operation: return [("양지우", "NativeOps"), ("안율", "FA"), ("김민준", "Leader")]
        case .etc: return [("이시우", "Leader · iOS"), ("양지우", "StudyLeader · FE")]
        }
    }
}

/// 05-11 · 05-12 · 05-13 요청서 작성
@Observable
@MainActor
final class RequestFormViewModel {
    let kind: RequestFormKind
    /// 프로젝트 · 담당 부서 선택지
    let targets: [String]

    var title = ""
    var target: String
    var desiredDate: Date
    var category: String?
    /// 필요 인원 (프로젝트) · 수량 (운영)
    var quantity = ""
    /// 기간 (프로젝트) 예) 10.23 – 10.31
    var period = ""
    var amountText = ""
    var body = ""
    private(set) var attachmentNames: [String] = []
    var isDatePickerPresented = false
    var isFileImporterPresented = false
    private(set) var isSubmitting = false
    var errorMessage: String?

    private let submitDocumentUseCase: SubmitDocumentUseCase

    init(kind: RequestFormKind, submitDocumentUseCase: SubmitDocumentUseCase, now: Date = Date()) {
        self.kind = kind
        self.submitDocumentUseCase = submitDocumentUseCase
        self.desiredDate = now
        switch kind {
        case .project: targets = ["Book-on", "Native 팀스페이스", "MoSS"]
        case .operation: targets = ["NativeOps", "PMO", "FA", "Leader"]
        case .etc: targets = []
        }
        self.target = targets.first ?? ""
        self.category = kind.categories.first
    }

    var amount: Int {
        Int(amountText.filter(\.isNumber)) ?? 0
    }

    var formattedAmount: String {
        amount == 0 ? "" : TSFormat.number(amount)
    }

    func updateAmount(_ text: String) {
        amountText = String(text.filter(\.isNumber).prefix(10))
    }

    func addAttachment(named name: String) {
        guard !attachmentNames.contains(name) else { return }
        attachmentNames.append(name)
    }

    func removeAttachment(named name: String) {
        attachmentNames.removeAll { $0 == name }
    }

    /// 요청 제목 — 기타 문서는 직접 입력, 나머지는 분류 + 대상으로 만들어요.
    var documentTitle: String {
        switch kind {
        case .etc: return title.trimmingCharacters(in: .whitespaces)
        case .project, .operation: return "\(target) \(category ?? "") 요청".replacingOccurrences(of: "  ", with: " ")
        }
    }

    var canSubmit: Bool {
        !documentTitle.isEmpty && !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    var draft: DocumentDraft {
        DocumentDraft(
            kind: kind.approvalKind,
            title: documentTitle,
            amount: kind == .operation && amount > 0 ? amount : nil,
            fields: fields,
            reason: body,
            attachmentNames: attachmentNames
        )
    }

    private var fields: [ApprovalField] {
        let date = TSFormat.fullDate(desiredDate)
        switch kind {
        case .project:
            return [
                ApprovalField(title: "프로젝트", value: target),
                ApprovalField(title: "요청 종류", value: category ?? "-"),
                ApprovalField(title: "필요 인원", value: quantity.isEmpty ? "-" : quantity),
                ApprovalField(title: "기간", value: period.isEmpty ? "-" : period),
                ApprovalField(title: "희망 반영일", value: date)
            ]
        case .operation:
            return [
                ApprovalField(title: "담당 부서", value: target),
                ApprovalField(title: "요청 분류", value: category ?? "-"),
                ApprovalField(title: "수량", value: quantity.isEmpty ? "-" : quantity),
                ApprovalField(title: "희망 처리일", value: date)
            ]
        case .etc:
            return []
        }
    }

    func submit() async -> SubmittedDocument? {
        await run { try await self.submitDocumentUseCase.submit(self.draft) }
    }

    func saveDraft() async -> Bool {
        await run { try await self.submitDocumentUseCase.saveDraft(self.draft) } != nil
    }

    private func run(_ work: () async throws -> Int) async -> SubmittedDocument? {
        guard !isSubmitting else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let id = try await work()
            return SubmittedDocument(documentId: id, firstApproverName: kind.approvalLine.first?.name ?? "")
        } catch {
            AppLog.record(error, context: "approval.requestForm")
            errorMessage = error.userMessage
            return nil
        }
    }
}
