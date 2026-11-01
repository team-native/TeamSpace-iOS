import SwiftUI

/// 10-7 전체 공지 작성 [담당자 운영 화면] — 대상 · 표시 · 제목 · 본문 · 첨부 · 게시 시점 · 푸시 · 게시 전 확인
struct NoticeComposeView: View {
    @State private var viewModel: NoticeComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: NoticeComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    StatusBadge(title: "공지 게시 권한 · NativeOps", tone: .primary, size: .small)
                    WorkspacePageTitle(eyebrow: "대상과 게시 시점을 확인한 뒤 공지해 주세요.", title: "팀에 필요한 소식을 전해요")
                }
                NoticeAudienceSection(viewModel: viewModel)
                NoticeTextSection(viewModel: viewModel)
                NoticeAttachmentSection(viewModel: viewModel)
                NoticeTimingSection(viewModel: viewModel)
                NoticePushPreview(audience: viewModel.draft.audience, isEnabled: viewModel.draft.sendsPush)
                NoticeChecklistCard(lines: viewModel.draft.checklist)
                InfoBanner(message: "푸시는 수신 설정과 기기 권한에 따라 표시돼요. 예약 등록 후에도 게시 전까지 수정·취소할 수 있어요.", style: .muted)
                actions
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "전체 공지 작성", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .modifier(NoticeComposeAlerts(viewModel: viewModel, onDone: { dismiss() }))
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button(viewModel.draft.publishTitle) { Task { await viewModel.publish() } }
                .buttonStyle(.tsPrimaryLarge)
                .disabled(!viewModel.canPublish)
            Button("임시 저장") { Task { await viewModel.saveDraft() } }
                .buttonStyle(.tsSecondary)
                .disabled(viewModel.isSubmitting)
        }
    }
}

/// 게시 완료 · 오류 알림
private struct NoticeComposeAlerts: ViewModifier {
    @Bindable var viewModel: NoticeComposeViewModel
    let onDone: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(viewModel.completionMessage ?? "", isPresented: Binding(
                get: { viewModel.completionMessage != nil },
                set: { if !$0 { viewModel.completionMessage = nil } }
            )) {
                Button("확인", action: onDone)
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
        NoticeComposeView(
            viewModel: DIContainer.preview().makeNoticeComposeViewModel(user: AuthUser(id: 1, name: "김민준", roles: [.fa]))
        )
    }
}
