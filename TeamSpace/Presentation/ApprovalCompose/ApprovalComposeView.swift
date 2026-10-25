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

    @State private var activeSheet: ApprovalComposeKind?
    @State private var submitted: SubmittedDocument?
    @Environment(\.dismiss) private var dismiss

    init(container: DIContainer, onNavigate: @escaping (AppRoute) -> Void) {
        self.container = container
        self.onNavigate = onNavigate
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
        switch kind {
        case .expense, .staffing:
            activeSheet = kind
        case .projectRequest, .operationRequest, .etcDocument:
            onNavigate(.comingSoon(title: kind.title))
        }
    }

    @ViewBuilder
    private func sheet(for kind: ApprovalComposeKind) -> some View {
        let onFinish: (SubmittedDocument?) -> Void = { result in
            activeSheet = nil
            submitted = result
        }
        switch kind {
        case .staffing:
            StaffingRequestSheet(viewModel: container.makeStaffingRequestViewModel(), onFinish: onFinish)
        default:
            ExpenseRequestSheet(viewModel: container.makeExpenseRequestViewModel(), onFinish: onFinish)
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
