import SwiftUI

/// 계약 정보 등록 · 수정 [FA · Admin] — 담당 PM · 계약일 · 금액 · 진행 단계 · 인원 · 풀 배분 · 다음 일정
struct ContractInfoComposeView: View {
    @State private var viewModel: ContractInfoComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractInfoComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                InfoBanner(message: "\(viewModel.project) 계약 정보예요.", style: .muted)
                ComposeField(label: "담당 PM") {
                    TextField("예) 이시우 · PM", text: $viewModel.draft.pm)
                        .tsFont(.callout)
                }
                WorkspaceCard {
                    DatePicker("계약일", selection: $viewModel.draft.signedDate, displayedComponents: .date)
                        .tsFont(.footnote)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
                ComposeField(label: "계약 금액 (원)") {
                    TextField("예) 3600000", text: $viewModel.draft.totalText)
                        .keyboardType(.numberPad)
                        .tsFont(.callout)
                }
                ComposeField(label: "받은 금액 (원)") {
                    TextField("예) 1800000", text: $viewModel.draft.collectedText)
                        .keyboardType(.numberPad)
                        .tsFont(.callout)
                }
                WorkspaceCard {
                    Stepper(value: $viewModel.draft.step, in: 0...ContractInfoDraft.stepTitles.count) {
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text("진행 단계")
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            Text(viewModel.draft.stepText)
                                .tsFont(.caption)
                                .foregroundStyle(Color.tsInk3)
                        }
                    }
                }
                ComposeField(label: "참여 인원") {
                    TextField("예) iOS 2 · Design 1 · Backend 1", text: $viewModel.draft.staff)
                        .tsFont(.callout)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ComposeField(label: "풀 배분") {
                        TextField("예) 운영 60% · 적립 30% · 배당 10%", text: $viewModel.draft.split)
                            .tsFont(.callout)
                    }
                    if let splitText = viewModel.splitText {
                        Text(splitText)
                            .tsFont(.caption)
                            .foregroundStyle(viewModel.draft.splitTotal == 100 ? Color.tsInk3 : Color.tsNegative)
                    }
                }
                ComposeField(label: "다음 일정") {
                    TextField("예) 11.20 잔금 예정", text: $viewModel.draft.next)
                        .tsFont(.callout)
                }
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
}

/// 수주 상세를 불러와 계약 정보 화면을 열어요.
struct ContractInfoEditView: View {
    @State private var viewModel: ContractDetailViewModel
    private let container: DIContainer
    private let user: AuthUser

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ContractDetailViewModel, container: DIContainer, user: AuthUser) {
        _viewModel = State(initialValue: viewModel)
        self.container = container
        self.user = user
    }

    var body: some View {
        Group {
            if let detail = viewModel.state.value, user.can(.manageReceipts) {
                ContractInfoComposeView(viewModel: container.makeContractInfoComposeViewModel(user: user, detail: detail))
            } else {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    switch viewModel.state {
                    case .idle, .loading:
                        LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
                    case .failed(let error):
                        ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
                    case .empty, .forbidden, .loaded:
                        InfoBanner(message: "계약 정보는 FA · 관리자만 고칠 수 있어요.", icon: .infoCircle, style: .muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.screen)
                .safeAreaInset(edge: .top, spacing: 0) {
                    TSNavigationBar(title: "계약 정보", onBack: { dismiss() })
                        .padding(.horizontal, Spacing.screen)
                        .padding(.bottom, Spacing.sm)
                        .background(Color.tsBackground)
                }
                .background(Color.tsBackground.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .task { if viewModel.state.value == nil { await viewModel.load() } }
    }
}
