import SwiftUI

/// 08-7 PM 지원자 검토 (PM · Admin)
struct ApplicantReviewView: View {
    @State private var viewModel: ApplicantReviewViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ApplicantReviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "지원자 검토", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(ApplicantReviewAlerts(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "지원자 정보는 해당 프로젝트 PM 등 허용된 담당자만 볼 수 있어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let board):
            ApplicantBoardHeader(board: board, viewModel: viewModel)
            if viewModel.applicants.isEmpty {
                InfoBanner(message: "아직 지원자가 없어요.", icon: .infoCircle, style: .muted)
            }
            ForEach(viewModel.applicants) { applicant in
                if applicant.id == viewModel.selectedId {
                    SelectedApplicantCard(applicant: applicant, viewModel: viewModel)
                } else {
                    ApplicantCompactCard(applicant: applicant) { viewModel.select(applicant) }
                }
            }
            WorkspaceNote(message: "다른 지원자의 정보는 해당 프로젝트 PM 등 허용된 담당자만 볼 수 있어요. 일반 구성원에게는 본인의 신청만 보여요. 결과는 신청자의 개인 업무 알림으로 전달돼요.")
        }
    }
}

/// 결과 등록 완료 · 오류 알림
private struct ApplicantReviewAlerts: ViewModifier {
    @Bindable var viewModel: ApplicantReviewViewModel

    func body(content: Content) -> some View {
        content
            .alert("결과를 등록했어요", isPresented: Binding(
                get: { viewModel.doneMessage != nil },
                set: { if !$0 { viewModel.doneMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(viewModel.doneMessage ?? "")
            }
            .alert(viewModel.errorMessage ?? "", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            }
    }
}

#Preview {
    NavigationStack {
        ApplicantReviewView(viewModel: DIContainer.preview().makeApplicantReviewViewModel(projectId: 1))
    }
}
