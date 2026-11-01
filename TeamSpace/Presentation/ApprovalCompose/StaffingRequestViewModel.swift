import Foundation
import Observation

/// 05-6 프로젝트 인력 지원
@Observable
@MainActor
final class StaffingRequestViewModel {
    /// 고를 수 있는 프로젝트 — 프로젝트 목록 API(08) 연결 전까지 임시 목록
    let projects = ["Book-on", "Native 팀스페이스", "MoSS"]
    static let headcountRange = 1...10

    var project = "Book-on"
    var role: StaffingRole = .iOS
    private(set) var headcount = 1
    var startMonth: Date
    var endMonth: Date
    var reason = ""
    var isPeriodPickerPresented = false
    private(set) var isSubmitting = false
    var errorMessage: String?

    private let submitDocumentUseCase: SubmitDocumentUseCase

    init(submitDocumentUseCase: SubmitDocumentUseCase, now: Date = Date()) {
        self.submitDocumentUseCase = submitDocumentUseCase
        let calendar = Calendar.current
        let thisMonth = calendar.startOfMonth(for: now)
        self.startMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth) ?? thisMonth
        self.endMonth = calendar.date(byAdding: .month, value: 2, to: thisMonth) ?? thisMonth
    }

    /// "11월 ~ 12월"
    var periodText: String {
        "\(TSFormat.month(startMonth)) ~ \(TSFormat.month(endMonth))"
    }

    var canSubmit: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    func changeHeadcount(by delta: Int) {
        headcount = min(max(headcount + delta, Self.headcountRange.lowerBound), Self.headcountRange.upperBound)
    }

    /// 종료 달이 시작 달보다 앞서면 시작 달로 맞춰요.
    func setPeriod(start: Date, end: Date) {
        startMonth = start
        endMonth = max(start, end)
        isPeriodPickerPresented = false
    }

    var draft: DocumentDraft {
        DocumentDraft(
            kind: .staffing,
            title: "\(project) 프로젝트 인력 지원",
            amount: nil,
            fields: [
                ApprovalField(title: "프로젝트", value: project),
                ApprovalField(title: "필요 직군", value: role.rawValue),
                ApprovalField(title: "인원", value: "\(headcount)명"),
                ApprovalField(title: "투입 기간", value: "\(Self.monthText(startMonth)) ~ \(Self.monthText(endMonth))")
            ],
            reason: reason,
            attachmentNames: []
        )
    }

    func submit() async -> SubmittedDocument? {
        guard !isSubmitting else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let id = try await submitDocumentUseCase.submit(draft)
            return SubmittedDocument(documentId: id, firstApproverName: ApprovalLinePreview.defaultLine.first?.name ?? "")
        } catch {
            AppLog.record(error, context: "approval.staffing")
            errorMessage = error.userMessage
            return nil
        }
    }

    /// "2026.11"
    private static func monthText(_ date: Date) -> String {
        let calendar = Calendar.current
        return String(format: "%04d.%02d", calendar.component(.year, from: date), calendar.component(.month, from: date))
    }
}
