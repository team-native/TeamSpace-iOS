import SwiftUI

/// 08-2 프로젝트 상세
struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    private let onNavigate: (AppRoute) -> Void
    /// PM · Admin — 08-7 지원자 검토 버튼
    private let canReviewApplicants: Bool
    /// Admin — 프로젝트 수정 버튼
    private let canEdit: Bool

    @Environment(\.dismiss) private var dismiss

    init(
        viewModel: ProjectDetailViewModel,
        canReviewApplicants: Bool = false,
        canEdit: Bool = false,
        onNavigate: @escaping (AppRoute) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.canReviewApplicants = canReviewApplicants
        self.canEdit = canEdit
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
            TSNavigationBar(title: "프로젝트", onBack: { dismiss() }) {
                if canEdit, let id = viewModel.detail?.project.id {
                    CircleIconButton(icon: .pencil, accessibilityLabel: "프로젝트 수정", background: .tsSurface, hasBorder: true) {
                        onNavigate(.projectEdit(id: id))
                    }
                }
            }
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
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            AccessDeniedView(
                onInquire: { onNavigate(.inquiryCompose(.accessRequest)) },
                onBack: { dismiss() }
            )
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
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
            if canEdit {
                Button(detail.project.openings.isEmpty ? "모집 자리 열기" : "모집 자리 관리") {
                    onNavigate(.projectOpenings(id: detail.project.id))
                }
                .buttonStyle(.tsSecondary)
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
        ProjectDetailView(viewModel: DIContainer.preview().makeProjectDetailViewModel(projectId: "book-on"), onNavigate: { _ in })
    }
}
