import SwiftUI

/// 11-2 문의 · 건의 작성 — 대상 부서 · 제목 · 내용 · 실명/익명 → 11-3 접수 알림
struct InquiryComposeView: View {
    @State private var viewModel: InquiryComposeViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: InquiryComposeViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    WorkspacePageTitle(eyebrow: "공식 채널", title: "더 나은 운영을 위한 목소리")
                    Text("게시판에 공개되지 않고 담당 부서에 직접 전달돼요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
                if viewModel.isFollowUp {
                    InfoBanner(message: "이전 문의에 이어서 보내는 후속 문의예요.", icon: .infoCircle)
                }
                InquiryDepartmentSection(viewModel: viewModel)
                InquiryTextSection(viewModel: viewModel)
                InquiryAuthorSection(viewModel: viewModel)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "문의 · 건의", onBack: { dismiss() }) {
                Button("내 문의") { onNavigate(.myInquiries) }
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
        .modifier(InquiryComposeAlerts(viewModel: viewModel, onClose: { dismiss() }, onShowMine: showMine))
    }

    /// 11-3 "내 문의 보기" — 작성 화면을 닫은 뒤 11-1을 열어요.
    private func showMine() {
        dismiss()
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            onNavigate(.myInquiries)
        }
    }
}

/// 11-3 문의 접수 · 오류 알림
private struct InquiryComposeAlerts: ViewModifier {
    @Bindable var viewModel: InquiryComposeViewModel
    let onClose: () -> Void
    let onShowMine: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("문의가 접수됐어요", isPresented: Binding(
                get: { viewModel.submitted != nil },
                set: { if !$0 { viewModel.submitted = nil } }
            )) {
                Button("내 문의 보기", action: onShowMine)
                Button("확인", action: onClose)
            } message: {
                Text(viewModel.submittedMessage)
            }
            .alert(viewModel.errorMessage ?? "", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            }
    }
}

/// 11-2 문의 대상 — Leader · NativeOps · PMO · FA
private struct InquiryDepartmentSection: View {
    @Bindable var viewModel: InquiryComposeViewModel

    private let columns = [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "문의 대상")
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(InquiryDepartment.selectable, id: \.self) { department in
                    let isSelected = viewModel.draft.department == department
                    Button { viewModel.draft.department = department } label: {
                        Text(department.title)
                            .tsFont(isSelected ? .footnoteBold : .footnote)
                            .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk2)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(isSelected ? Color.tsPrimary : Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            Text(viewModel.draft.department.scopeText)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

/// 11-2 제목 · 내용
private struct InquiryTextSection: View {
    @Bindable var viewModel: InquiryComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            ComposeField(label: "제목") {
                TextField("어떤 점을 알리고 싶나요?", text: $viewModel.draft.title)
                    .tsFont(.callout)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                PostComposeLabel(title: "내용", trailing: viewModel.bodyCountText)
                TextEditor(text: $viewModel.draft.body)
                    .tsFont(.callout)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
                    .padding(Spacing.md)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    .accessibilityLabel("내용")
            }
        }
    }
}

/// 11-2 작성자 표시 — 실명 · 익명
private struct InquiryAuthorSection: View {
    @Bindable var viewModel: InquiryComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "작성자 표시")
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
        InquiryComposeView(viewModel: DIContainer.preview().makeInquiryComposeViewModel(context: .blank), onNavigate: { _ in })
    }
}
