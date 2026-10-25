import Foundation

/// POST /documents — 작성 · 임시 저장할 결재 문서
struct DocumentDraft: Equatable, Sendable {
    let kind: ApprovalKind
    let title: String
    /// 비용 승인만 금액이 있어요.
    let amount: Int?
    /// 화면에 그대로 보여줄 항목 (비용 유형 · 프로젝트 · 사용 예정일 …)
    let fields: [ApprovalField]
    let reason: String
    /// 첨부 파일 이름 (업로드 API 가 생기면 파일 ID 로 바꿔요)
    let attachmentNames: [String]
}

/// 비용 유형 (05-6a)
enum ExpenseType: String, CaseIterable, Hashable, Sendable {
    case purchase = "물품 구매"
    case subscription = "도구 · 구독"
    case external = "외부 비용"
    case education = "교육 · 행사"
    case etc = "기타"
}

/// 프로젝트 인력 지원 직군 (05-6)
enum StaffingRole: String, CaseIterable, Hashable, Sendable {
    case iOS = "iOS"
    case frontend = "FE"
    case backend = "BE"
    case design = "Design"
    case pm = "PM"
}
