import SwiftUI

/// 12-3 운영 제안 쓰기 — 대상 부서 · 제목 · 내용 · 실명/익명 · 임시 저장
struct ProposalComposeView: View {
    @State private var viewModel: ProposalComposeViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProposalComposeViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                if viewModel.didRestoreDraft {
                    InfoBanner(message: "임시 저장한 제안을 불러왔어요.", icon: .infoCircle)
                }
                ProposalDepartmentSection(viewModel: viewModel)
                ProposalTextSection(viewModel: viewModel)
                ProposalAuthorSection(viewModel: viewModel)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "운영 제안 쓰기", onBack: { dismiss() }) {
                Button("임시 저장") {
                    viewModel.saveDraft()
                    dismiss()
                }
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsPrimary)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                .buttonStyle(.tsPrimaryLarge)
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, Spacing.screen)
                .padding(.vertical, Spacing.md)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .modifier(ProposalComposeAlerts(viewModel: viewModel, onClose: { dismiss() }, onShow: show))
    }

    /// "제안 보기" — 쓰기 화면을 닫은 뒤 상세를 열어요.
    private func show(_ proposal: ProposalSummary) {
        dismiss()
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            onNavigate(.proposalDetail(id: proposal.id))
        }
    }
}

/// 게시 완료 · 오류 알림
private struct ProposalComposeAlerts: ViewModifier {
    @Bindable var viewModel: ProposalComposeViewModel
    let onClose: () -> Void
    let onShow: (ProposalSummary) -> Void

    func body(content: Content) -> some View {
        content
            .alert("제안을 올렸어요", isPresented: Binding(
                get: { viewModel.published != nil },
                set: { if !$0 { viewModel.published = nil } }
            ), presenting: viewModel.published) { proposal in
                Button("확인", action: onClose)
                Button("제안 보기") { onShow(proposal) }
            } message: { _ in
                Text(viewModel.completionMessage)
            }
            .alert(viewModel.errorMessage ?? "", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            }
    }
}

/// 12-3 대상 부서 — NativeOps · PMO · FA · Design
private struct ProposalDepartmentSection: View {
    @Bindable var viewModel: ProposalComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "대상 부서")
            FlowLayout(spacing: Spacing.xs) {
                ForEach(ProposalDraft.departments, id: \.self) { department in
                    FilterChip(title: department, isSelected: viewModel.draft.department == department) {
                        viewModel.draft.department = department
                    }
                }
            }
        }
    }
}

/// 12-3 제목 · 내용 (96 / 2,000)
private struct ProposalTextSection: View {
    @Bindable var viewModel: ProposalComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("어떤 점을 바꾸면 좋을까요?", text: $viewModel.draft.title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(height: 50)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            TextEditor(text: $viewModel.draft.body)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 180)
                .padding(Spacing.md)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityLabel("제안 내용")
            HStack {
                Spacer()
                Text(viewModel.bodyCountText)
                    .tsFont(.caption2)
                    .foregroundStyle(viewModel.draft.body.count > ProposalDraft.bodyLimit ? Color.tsNegative : Color.tsInk3)
            }
        }
    }
}

/// 12-3 작성 방식 — 실명 · 익명
private struct ProposalAuthorSection: View {
    @Bindable var viewModel: ProposalComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "작성 방식")
            TSSegmentedControl(
                items: [false, true],
                selection: viewModel.draft.isAnonymous,
                title: { $0 ? "익명" : "실명" },
                onSelect: { viewModel.draft.isAnonymous = $0 }
            )
            Text(viewModel.authorNotice)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

#Preview {
    NavigationStack {
        ProposalComposeView(viewModel: DIContainer.preview().makeProposalComposeViewModel(), onNavigate: { _ in })
    }
}
