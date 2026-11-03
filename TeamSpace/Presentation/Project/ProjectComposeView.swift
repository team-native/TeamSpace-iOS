import SwiftUI

/// 프로젝트 등록 · 수정 [Admin] — 이름 · 한 줄 설명 · 담당 부서 · PM · 상태 · 기간 · 진행률
struct ProjectComposeView: View {
    @State private var viewModel: ProjectComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ComposeField(label: "프로젝트 이름") {
                    TextField("예) Book-on", text: $viewModel.draft.name)
                        .tsFont(.callout)
                }
                ComposeField(label: "한 줄 설명") {
                    TextField("예) 독서 기록 앱 · 그린랩 외주", text: $viewModel.draft.summary)
                        .tsFont(.callout)
                }
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        PostComposeLabel(title: "담당 부서")
                        Picker("담당 부서", selection: $viewModel.draft.department) {
                            ForEach(ProjectComposeViewModel.departments, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.tsInk)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    }
                    ComposeField(label: "PM") {
                        TextField("이름", text: $viewModel.draft.pmName)
                            .tsFont(.callout)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PostComposeLabel(title: "진행 상태")
                    TSSegmentedControl(
                        items: ProjectComposeViewModel.statuses,
                        selection: viewModel.draft.status,
                        title: \.serverValue,
                        onSelect: { viewModel.draft.status = $0 }
                    )
                }
                periodCard
                progressCard
                InfoBanner(message: viewModel.noticeText, style: .muted)
                Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSubmit)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: viewModel.screenTitle, onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .alert(viewModel.completionTitle, isPresented: $viewModel.didSave) {
            Button("확인") { dismiss() }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    private var periodCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "기간")
            WorkspaceCard {
                DatePicker("시작", selection: $viewModel.draft.startDate, displayedComponents: .date)
                    .tsFont(.footnote)
                TSDivider()
                DatePicker("마감", selection: $viewModel.draft.endDate, displayedComponents: .date)
                    .tsFont(.footnote)
            }
            .environment(\.locale, Locale(identifier: "ko_KR"))
            if let hint = viewModel.periodHint {
                Text(hint)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsNegative)
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "진행률", trailing: "\(viewModel.isProgressLocked ? 100 : viewModel.draft.progress)%")
            WorkspaceCard {
                Slider(
                    value: Binding(
                        get: { Double(viewModel.isProgressLocked ? 100 : viewModel.draft.progress) },
                        set: { viewModel.draft.progress = Int($0.rounded()) }
                    ),
                    in: 0...100,
                    step: 5
                )
                .tint(Color.tsPrimary)
                .disabled(viewModel.isProgressLocked)
                .accessibilityLabel("진행률")
                if viewModel.isProgressLocked {
                    Text("완료한 프로젝트는 100%로 저장돼요.")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectComposeView(viewModel: DIContainer.preview().makeProjectComposeViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin])))
    }
}
