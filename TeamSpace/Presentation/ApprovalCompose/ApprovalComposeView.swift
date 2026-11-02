import SwiftUI

/// 05-0 결재 올리기 — 종류 고르기
enum ApprovalComposeKind: String, CaseIterable, Identifiable {
    case expense
    case staffing
    case projectRequest
    case operationRequest
    case etcDocument

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: return "비용 승인 요청"
        case .staffing: return "프로젝트 인력 지원"
        case .projectRequest: return "프로젝트 관련 요청서"
        case .operationRequest: return "운영 관련 요청서"
        case .etcDocument: return "기타 내부 문서"
        }
    }

    var detail: String {
        switch self {
        case .expense: return "물품 · 도구 구독 · 외부 비용"
        case .staffing: return "필요한 직군과 인원 배정"
        case .projectRequest: return "일정 변경 · 예산 · 인원 조정"
        case .operationRequest: return "물품 · 시설 · 행사 · 규정"
        case .etcDocument: return "자유 양식 보고 · 공유"
        }
    }

    var icon: TSIcon {
        switch self {
        case .expense: return .wallet
        case .staffing: return .users
        case .projectRequest: return .calendar
        case .operationRequest: return .settings
        case .etcDocument: return .file
        }
    }
}

struct ApprovalComposeView: View {
    private let container: DIContainer
    private let onNavigate: (AppRoute) -> Void
    private let templateTitle: String?
    /// 고치는 결재 (작성 중 · 반려) — 있으면 그 종류 양식을 기존 내용으로 채워 열어요.
    private let editing: ApprovalDetail?

    @State private var activeSheet: ApprovalComposeKind?
    @State private var submitted: SubmittedDocument?
    @Environment(\.dismiss) private var dismiss

    init(
        container: DIContainer,
        onNavigate: @escaping (AppRoute) -> Void,
        initialKind: ApprovalComposeKind? = nil,
        templateTitle: String? = nil,
        editing: ApprovalDetail? = nil
    ) {
        self.container = container
        self.onNavigate = onNavigate
        self.templateTitle = templateTitle
        self.editing = editing
        _activeSheet = State(initialValue: editing?.item.kind.composeKind ?? initialKind)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ScreenTitle(title: "어떤 결재를 올릴까요?", subtitle: "필요한 유형을 선택해 주세요")
                ForEach(ApprovalComposeKind.allCases) { kind in
                    Button { open(kind) } label: { ComposeKindCard(kind: kind) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "결재 올리기", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { kind in
            sheet(for: kind)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Radius.sheet)
        }
        .overlay {
            if let submitted {
                SubmitCompletedDialog(
                    firstApproverName: submitted.firstApproverName,
                    onShowDocument: {
                        self.submitted = nil
                        onNavigate(.approvalDetail(documentId: submitted.documentId))
                    },
                    onConfirm: {
                        self.submitted = nil
                        dismiss()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: submitted)
    }

    private func open(_ kind: ApprovalComposeKind) {
        activeSheet = kind
    }

    @ViewBuilder
    private func sheet(for kind: ApprovalComposeKind) -> some View {
        let onFinish: (SubmittedDocument?) -> Void = { result in
            activeSheet = nil
            submitted = result
        }
        // 고치는 결재와 같은 종류를 열 때만 기존 내용을 채워요.
        let editing = editing.flatMap { $0.item.kind.composeKind == kind ? $0 : nil }
        switch kind {
        case .expense:
            let viewModel = container.makeExpenseRequestViewModel()
            let _ = editing.map(viewModel.prefill)
            ExpenseRequestSheet(viewModel: viewModel, onFinish: onFinish)
        case .staffing:
            let viewModel = container.makeStaffingRequestViewModel()
            let _ = editing.map(viewModel.prefill)
            StaffingRequestSheet(viewModel: viewModel, onFinish: onFinish)
        case .projectRequest, .operationRequest, .etcDocument:
            let formKind: RequestFormKind = kind == .projectRequest ? .project : kind == .operationRequest ? .operation : .etc
            let viewModel = container.makeRequestFormViewModel(kind: formKind, initialTitle: formKind == .etc ? templateTitle ?? "" : "")
            let _ = editing.map(viewModel.prefill)
            RequestFormSheet(viewModel: viewModel, onFinish: onFinish)
        }
    }
}

/// 제출이 끝난 문서 — 05-7 알림창에 사용
struct SubmittedDocument: Equatable {
    let documentId: Int
    let firstApproverName: String
}

private struct ComposeKindCard: View {
    let kind: ApprovalComposeKind

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            IconTile(icon: kind.icon, iconSize: .xlLarge, tileSize: 46)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(kind.title)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(kind.detail)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
                HStack(spacing: Spacing.xxs) {
                    Text("요청하기")
                        .tsFont(.footnoteBold)
                    TSIcon.arrowRight.sized(.mdLarge)
                }
                .foregroundStyle(Color.tsPrimary)
                .padding(.top, Spacing.xs)
            }
            Spacer(minLength: 0)
        }
        .tsCard(padding: Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ApprovalComposeView(container: .preview(), onNavigate: { _ in })
    }
}
