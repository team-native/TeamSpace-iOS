import SwiftUI

/// 08-6 내 참여 신청 현황
struct MyApplicationsView: View {
    @State private var viewModel: MyApplicationsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyApplicationsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                WorkspacePageTitle(eyebrow: "내가 낸 신청이 어디까지 왔는지 확인해요", title: "함께할 준비를 하고 있어요")
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(ApplicationFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter == .all ? "전체 \(viewModel.count(of: .all))" : filter.title,
                            isSelected: viewModel.filter == filter
                        ) { viewModel.filter = filter }
                    }
                }
                content
                Text("참여 신청 상태는 문서 결재 상태와 별도로 관리돼요.")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk2)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 참여 신청", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(CancelApplicationDialog(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "신청 현황을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.applications.isEmpty {
                InfoBanner(message: "이 상태의 신청이 없어요. 전체 프로젝트에서 모집 중인 자리를 찾아보세요.", icon: .infoCircle, style: .muted)
            }
            ForEach(viewModel.applications) { application in
                if viewModel.isExpanded(application) {
                    ApplicationDetailCard(
                        application: application,
                        onAskPM: { onNavigate(.comingSoon(title: "PM에게 수정 문의")) },
                        onCancel: { viewModel.pendingCancel = application },
                        onCollapse: { viewModel.toggle(application) }
                    )
                } else {
                    ApplicationCompactCard(application: application) {
                        if application.status == .accepted {
                            onNavigate(.projectDetail(id: application.projectId))
                        } else {
                            viewModel.toggle(application)
                        }
                    }
                }
            }
        }
    }
}

/// 신청 취소 확인 · 오류 알림
private struct CancelApplicationDialog: ViewModifier {
    @Bindable var viewModel: MyApplicationsViewModel

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "신청을 취소할까요?",
                isPresented: Binding(
                    get: { viewModel.pendingCancel != nil },
                    set: { if !$0 { viewModel.pendingCancel = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("신청 취소", role: .destructive) { Task { await viewModel.confirmCancel() } }
                Button("닫기", role: .cancel) { viewModel.pendingCancel = nil }
            } message: {
                Text("취소하면 PM에게 보낸 신청서가 사라져요. 모집 기간 안에는 다시 신청할 수 있어요.")
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
        MyApplicationsView(viewModel: DIContainer.preview().makeMyApplicationsViewModel(), onNavigate: { _ in })
    }
}
