import SwiftUI

/// 08-1 전체 프로젝트 탐색
struct ProjectListView: View {
    @State private var viewModel: ProjectListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WorkspacePageTitle(eyebrow: "나에게 맞는 프로젝트를 찾아 함께 만들어 나가요", title: "함께할 프로젝트를 찾아요")
                    Text("내 참여 여부와 관계없이 조직의 프로젝트를 살펴보세요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                }
                SearchField(placeholder: "프로젝트명, 설명, PM 검색", text: $viewModel.query)
                ProjectFilterBar(viewModel: viewModel)
                content
                Button("내 참여 신청 현황") { onNavigate(.myApplications) }
                    .buttonStyle(.tsSecondary)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "전체 프로젝트", onBack: { dismiss() })
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
            InfoBanner(message: "프로젝트를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            HStack {
                Text(viewModel.countText)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                Spacer()
                StatusBadge(title: "최근 업데이트순", tone: .neutral, size: .small)
            }
            if viewModel.projects.isEmpty {
                InfoBanner(message: viewModel.emptyMessage, icon: .search, style: .muted)
            }
            ForEach(viewModel.projects) { project in
                ProjectCard(project: project) {
                    onNavigate(project.isRecruiting ? .projectRecruitment(id: project.id) : .projectDetail(id: project.id))
                }
            }
        }
    }
}

/// 08-1 상태 칩 + 부서 · 모집 중만 · 내 관심 직군
private struct ProjectFilterBar: View {
    @Bindable var viewModel: ProjectListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                ForEach(ProjectStatusFilter.allCases, id: \.self) { filter in
                    FilterChip(title: filter.title, isSelected: viewModel.statusFilter == filter) {
                        viewModel.statusFilter = filter
                    }
                }
            }
            HStack(spacing: Spacing.xs) {
                Menu {
                    Button("부서 전체") { viewModel.department = nil }
                    ForEach(viewModel.departments, id: \.self) { name in
                        Button(name) { viewModel.department = name }
                    }
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Text(viewModel.departmentTitle)
                        TSIcon.chevronDown.sized(.xs, weight: .bold)
                    }
                    .tsFont(.captionBold)
                    .foregroundStyle(Color.tsOnPrimary)
                    .padding(.horizontal, Spacing.md + Spacing.xxxs)
                    .frame(height: 30)
                    .background(Color.tsPrimary, in: Capsule())
                }
                FilterChip(title: "모집 중만", isSelected: viewModel.recruitingOnly) { viewModel.recruitingOnly.toggle() }
                FilterChip(title: "내 관심 직군", isSelected: viewModel.interestOnly) { viewModel.interestOnly.toggle() }
            }
        }
    }
}

/// 08-1 프로젝트 카드
struct ProjectCard: View {
    let project: ProjectSummary
    let onOpen: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(project.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: project.status, size: .small)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(project.name)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(project.cardDescription)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            WorkspaceLinkRow(title: project.linkTitle, action: onOpen)
        }
    }
}

#Preview {
    NavigationStack {
        ProjectListView(viewModel: DIContainer.preview().makeProjectListViewModel(), onNavigate: { _ in })
    }
}
