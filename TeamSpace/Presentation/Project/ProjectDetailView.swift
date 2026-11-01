import SwiftUI

/// 08-2 프로젝트 상세
struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    private let onNavigate: (AppRoute) -> Void
    /// PM · Admin — 08-7 지원자 검토 버튼
    private let canReviewApplicants: Bool

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectDetailViewModel, canReviewApplicants: Bool = false, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.canReviewApplicants = canReviewApplicants
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "프로젝트", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomAction }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 프로젝트를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            ProjectDetailHeader(project: detail.project)
            ProjectProgressCard(project: detail.project)
            ProjectInfoCard(project: detail.project)
            ProjectMembersRow(members: detail.members)
            if let opening = detail.project.openings.first {
                ProjectOpeningCard(opening: opening)
                if canReviewApplicants {
                    Button("지원자 검토 (PM)") { onNavigate(.applicantReview(projectId: detail.project.id)) }
                        .buttonStyle(.tsSecondary)
                }
            }
            ProjectRelatedCard(items: detail.relatedItems) { item in
                switch item.kind {
                case .schedule: onNavigate(.projectTimeline(id: detail.project.id))
                case .document, .unknown: onNavigate(.comingSoon(title: item.title))
                }
            }
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        if let detail = viewModel.detail {
            Group {
                if viewModel.canApply {
                    Button("참여 신청하기") { onNavigate(.projectRecruitment(id: detail.project.id)) }
                        .buttonStyle(.tsPrimaryLarge)
                } else if detail.isJoined {
                    Button("프로젝트 일정 보기") { onNavigate(.projectTimeline(id: detail.project.id)) }
                        .buttonStyle(.tsPrimaryLarge)
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.vertical, Spacing.md)
            .background(Color.tsBackground)
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(viewModel: DIContainer.preview().makeProjectDetailViewModel(projectId: 1), onNavigate: { _ in })
    }
}
