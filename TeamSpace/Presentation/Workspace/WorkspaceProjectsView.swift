import SwiftUI

/// 07-6 참여 프로젝트
struct WorkspaceProjectsView: View {
    @State private var viewModel: WorkspaceProjectsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: WorkspaceProjectsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                HStack {
                    Text("참여 중인 프로젝트")
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("전체 \(viewModel.projects.count)")
                        .tsFont(.footnoteMedium)
                        .foregroundStyle(Color.tsInk3)
                }
                .padding(.top, Spacing.xxl)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "참여 프로젝트", onBack: { dismiss() })
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
        case .empty:
            InfoBanner(message: "아직 참여 중인 프로젝트가 없어요. 모집 중인 프로젝트에 참여하면 여기에 보여요.", icon: .infoCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "프로젝트를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let projects):
            VStack(spacing: 0) {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    if index > 0 { TSDivider() }
                    Button { onNavigate(.projectDetail(id: project.id)) } label: { JoinedProjectRow(project: project) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, Spacing.xs)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

/// 프로젝트 한 줄 — 첫 글자 타일 · 이름 · 기간 · 상태
private struct JoinedProjectRow: View {
    let project: JoinedProject

    var body: some View {
        HStack(spacing: Spacing.lg - 2) {
            Text(project.initial)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.tsPrimary)
                .frame(width: 42, height: 42)
                .background(Color.tsPrimarySoft, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(project.name)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text(project.periodText)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
                    .lineLimit(1)
            }
            Spacer(minLength: Spacing.sm)
            StatusBadge(status: project.status)
        }
        .frame(minHeight: 75)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        WorkspaceProjectsView(viewModel: DIContainer.preview().makeWorkspaceProjectsViewModel(), onNavigate: { _ in })
    }
}
