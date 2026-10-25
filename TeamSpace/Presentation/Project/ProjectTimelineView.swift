import SwiftUI

/// 08-8 프로젝트 일정과 변경 이력 — 칩을 누르면 그 섹션으로 이동해요.
struct ProjectTimelineView: View {
    @State private var viewModel: ProjectTimelineViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectTimelineViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(viewModel.title)
                            .tsFont(.title3)
                            .foregroundStyle(Color.tsInk)
                            .accessibilityAddTraits(.isHeader)
                        if !viewModel.badgeText.isEmpty {
                            StatusBadge(title: viewModel.badgeText, tone: .primary, size: .small)
                        }
                    }
                    .padding(.top, Spacing.sm)
                    HStack(spacing: Spacing.xs) {
                        ForEach(ProjectTimelineViewModel.Section.allCases, id: \.self) { section in
                            FilterChip(title: section.title, isSelected: viewModel.selectedSection == section) {
                                viewModel.selectedSection = section
                                withAnimation { proxy.scrollTo(section, anchor: .top) }
                            }
                        }
                    }
                    content
                }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "프로젝트 일정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "이 프로젝트 일정을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let timeline):
            MilestoneCard(milestones: timeline.milestones)
                .id(ProjectTimelineViewModel.Section.milestones)
            MyProjectSchedulesCard(schedules: timeline.mySchedules) { onNavigate(.workspaceSchedules) }
                .id(ProjectTimelineViewModel.Section.mySchedules)
            Group {
                if let latest = viewModel.latestChange {
                    LatestChangeCard(change: latest) { onNavigate(.workspaceSchedules) }
                } else {
                    InfoBanner(message: "아직 바뀐 일정이 없어요.", icon: .infoCircle, style: .muted)
                }
            }
            .id(ProjectTimelineViewModel.Section.changes)
            ForEach(viewModel.olderChanges) { change in
                OlderChangeCard(
                    change: change,
                    isExpanded: viewModel.expandedChangeIds.contains(change.id),
                    onToggle: { viewModel.toggle(change) }
                )
            }
            WorkspaceNote(message: "참여 프로젝트의 일정 변경은 ‘개인 업무’예요. Native 전체 활동일·회의는 ‘Native 일정’으로 알려드려요.")
        }
    }
}

#Preview {
    NavigationStack {
        ProjectTimelineView(viewModel: DIContainer.preview().makeProjectTimelineViewModel(projectId: 1), onNavigate: { _ in })
    }
}
