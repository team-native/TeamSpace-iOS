import SwiftUI

/// 08-3 모집 공고 상세 (+ 08-4 신청 시트 · 08-5 완료 알림)
struct RecruitmentView: View {
    @State private var viewModel: RecruitmentViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: RecruitmentViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "모집 공고", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { applyButton }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(RecruitmentSheets(viewModel: viewModel, onShowApplications: { onNavigate(.myApplications) }))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "모집 공고를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let post):
            RecruitmentHeader(post: post)
            RecruitmentInfoCard(post: post)
            RecruitmentDutiesCard(post: post)
            RecruitmentPMCard(pmName: post.pmName, projectName: post.projectName) {
                onNavigate(.memberDirectory)
            }
            if let documentTitle = post.documentTitle {
                WorkspaceCard {
                    Text("관련 문서 · 프로젝트 소개와 역할")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk2)
                    Text(documentTitle)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                    WorkspaceLinkRow(title: "문서 확인") { onNavigate(.comingSoon(title: documentTitle)) }
                }
            }
            WorkspaceNote(message: "신청 결과는 ‘개인 업무’ 알림으로 안내해요. 이 화면은 프로젝트 소개가 아닌 모집 공고예요.")
        }
    }

    @ViewBuilder
    private var applyButton: some View {
        if let post = viewModel.post {
            Button(post.applyButtonTitle) { viewModel.isApplySheetPresented = true }
                .buttonStyle(.tsPrimaryLarge)
                .disabled(!post.canApply)
                .padding(.horizontal, Spacing.screen)
                .padding(.vertical, Spacing.md)
                .background(Color.tsBackground)
        }
    }
}

/// 08-4 신청 시트 · 08-5 신청 완료 · 오류 알림
private struct RecruitmentSheets: ViewModifier {
    @Bindable var viewModel: RecruitmentViewModel
    let onShowApplications: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isApplySheetPresented) {
                ApplySheet(viewModel: viewModel)
                    .presentationDetents([.height(520), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Radius.sheet)
            }
            .alert("신청을 보냈어요", isPresented: $viewModel.isSubmittedAlertPresented) {
                Button("확인", role: .cancel) {}
                Button("내 신청 보기", action: onShowApplications)
            } message: {
                Text("\(viewModel.post?.pmName ?? "PM") 님이 확인하면 알림으로 알려드려요.")
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("확인", role: .cancel) {}
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        RecruitmentView(viewModel: DIContainer.preview().makeRecruitmentViewModel(projectId: 4), onNavigate: { _ in })
    }
}
