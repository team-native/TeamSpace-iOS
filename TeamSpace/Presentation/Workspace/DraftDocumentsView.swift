import SwiftUI

/// 07-5 임시 저장 문서
struct DraftDocumentsView: View {
    @State private var viewModel: DraftDocumentsViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: DraftDocumentsViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                WorkspacePageTitle(eyebrow: "작성했던 곳부터, 내 생각을 다시 적어나갈 수 있어요", title: "작성하던 곳부터 이어가요")
                WorkspaceNote(message: syncMessage)
                content
                WebContinueCard()
                Text("이 목록은 아직 제출하지 않은 새 문서예요. 반려 후 재상신 문서는 ‘내가 제출한 문서’에서 확인해요. 삭제 전에는 확인 안내를 제공해요.")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "임시 저장", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(DraftDeleteDialog(viewModel: viewModel))
    }

    private var syncMessage: String {
        let base = "자동 저장된 문서는 같은 계정으로 앱과 웹에서 이어 쓸 수 있어요."
        guard let lastSync = viewModel.lastSyncText else { return base }
        return "\(base) \(lastSync)"
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty:
            InfoBanner(message: "임시 저장된 문서가 없어요. 결재 올리기에서 작성하다 저장하면 여기에 보여요.", icon: .infoCircle, style: .muted)
        case .forbidden:
            InfoBanner(message: "문서를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let drafts):
            ForEach(drafts) { draft in
                DraftDocumentCard(
                    document: draft,
                    onResume: { onNavigate(.approvalResume(kind: draft.kind.composeKind, title: draft.title)) },
                    onDelete: { viewModel.pendingDelete = draft }
                )
            }
        }
    }
}

/// 07-5 임시 문서 삭제 확인 · 오류 알림
private struct DraftDeleteDialog: ViewModifier {
    @Bindable var viewModel: DraftDocumentsViewModel

    func body(content: Content) -> some View {
        content
            .overlay {
                if let draft = viewModel.pendingDelete {
                    TSDialog(onDismiss: { viewModel.pendingDelete = nil }) {
                        VStack(spacing: Spacing.lg) {
                            Text("임시 문서를 삭제할까요?")
                                .tsFont(.headline)
                                .foregroundStyle(Color.tsInk)
                            Text("‘\(draft.title)’을(를) 삭제하면 앱과 웹 모두에서 사라지고 되돌릴 수 없어요.")
                                .tsFont(.footnote)
                                .foregroundStyle(Color.tsInk2)
                                .multilineTextAlignment(.center)
                            HStack(spacing: Spacing.sm) {
                                Button("취소") { viewModel.pendingDelete = nil }
                                    .buttonStyle(.tsSecondary)
                                Button("삭제") { Task { await viewModel.confirmDelete() } }
                                    .buttonStyle(.tsPrimary)
                                    .disabled(viewModel.isDeleting)
                            }
                        }
                        .padding(Spacing.xxl)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.pendingDelete)
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
        DraftDocumentsView(viewModel: DIContainer.preview().makeDraftDocumentsViewModel(), onNavigate: { _ in })
    }
}
