import SwiftUI

/// 07-18 프로젝트 목록 — 상태 칩 + 프로젝트 카드 (진행률 · 모집 중이면 지원하기)
struct WorkspaceProjectListView: View {
    @State private var viewModel: WorkspaceProjectListViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: WorkspaceProjectListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md + Spacing.xxxs) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                TSNavigationBar(title: "프로젝트", onBack: { dismiss() })
                if viewModel.state.value != nil {
                    FilterChipBar(
                        items: WorkspaceProjectTab.allCases,
                        selection: viewModel.tab,
                        title: \.title,
                        count: { viewModel.count(of: $0) },
                        onSelect: { viewModel.tab = $0 }
                    )
                }
            }
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
            LoadingSkeletonView(message: "프로젝트 목록을 불러오는 중이에요")
        case .empty:
            EmptyStateView(title: "아직 등록된 프로젝트가 없어요", message: "새 프로젝트가 시작되면 여기에 보여요.")
        case .forbidden:
            AccessDeniedView(onInquire: { onNavigate(.inquiryCompose(.accessRequest)) }, onBack: { dismiss() })
        case .failed(let error):
            ErrorStateView(message: error.userMessage, onBack: { dismiss() }) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.projects.isEmpty {
                InfoBanner(message: "이 상태의 프로젝트가 없어요.", icon: .infoCircle, style: .muted)
            }
            ForEach(viewModel.projects) { project in
                WorkspaceProjectListCard(
                    project: project,
                    metaText: viewModel.metaText(for: project),
                    onOpen: { onNavigate(.projectDetail(id: project.id)) },
                    onApply: { onNavigate(.projectRecruitment(id: project.id)) }
                )
            }
        }
    }
}

/// 07-18 프로젝트 카드 한 장
private struct WorkspaceProjectListCard: View {
    let project: ProjectSummary
    let metaText: String
    let onOpen: () -> Void
    let onApply: () -> Void

    var body: some View {
        Button(action: project.isRecruiting ? onApply : onOpen) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(alignment: .top) {
                        Text(project.name)
                            .tsFont(.bodyBold)
                            .foregroundStyle(Color.tsInk)
                        Spacer(minLength: Spacing.sm)
                        badge
                    }
                    Text(metaText)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                }
                if project.isRecruiting {
                    recruitingFooter
                } else {
                    progressFooter
                }
            }
            .padding(Spacing.card)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(project.isRecruiting ? "모집 공고를 열어요" : "프로젝트 상세를 열어요")
    }

    @ViewBuilder
    private var badge: some View {
        if project.isRecruiting {
            StatusBadge(title: "모집 중", tone: .violet, size: .small)
        } else {
            StatusBadge(status: project.status, size: .small)
        }
    }

    private var tint: Color {
        project.status == .completed ? .tsPositive : .tsPrimary
    }

    private var progressFooter: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TSProgressBar(percent: project.progress, tint: tint)
            HStack {
                Text("\(project.progress)%")
                    .tsFont(.captionBold)
                    .foregroundStyle(tint)
                Spacer()
                Text("프로젝트 상세")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
                    .accessibilityHidden(true)
            }
        }
    }

    private var recruitingFooter: some View {
        HStack {
            Text(project.openingsNeedText)
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            Spacer(minLength: Spacing.sm)
            Text("지원하기")
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsOnPrimary)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(minHeight: 33)
                .background(Color.tsPrimary, in: RoundedRectangle(cornerRadius: Radius.xs + 1, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        WorkspaceProjectListView(viewModel: DIContainer.preview().makeWorkspaceProjectListViewModel(), onNavigate: { _ in })
    }
}
