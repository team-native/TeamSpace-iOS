import SwiftUI

/// 수금 등록 · 수정 [FA · Admin] — 클라이언트 · 프로젝트 · 금액 · 상태 · 날짜
struct ReceiptComposeView: View {
    @State private var viewModel: ReceiptComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ReceiptComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ComposeField(label: "클라이언트") {
                    TextField("예) BRIDGE", text: $viewModel.draft.client)
                        .tsFont(.callout)
                }
                ComposeField(label: "프로젝트") {
                    TextField("예) iOS 앱 프로토타입", text: $viewModel.draft.project)
                        .tsFont(.callout)
                }
                ComposeField(label: "금액 (원)") {
                    TextField("예) 3600000", text: $viewModel.draft.amountText)
                        .keyboardType(.numberPad)
                        .tsFont(.callout)
                }
                if let amountPreview = viewModel.amountPreview {
                    Text(amountPreview)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk2)
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PostComposeLabel(title: "상태")
                    TSSegmentedControl(
                        items: ReceiptStatus.allCases,
                        selection: viewModel.draft.status,
                        title: \.rawValue,
                        onSelect: { viewModel.draft.status = $0 }
                    )
                }
                WorkspaceCard {
                    DatePicker("입금(예정)일", selection: $viewModel.draft.date, displayedComponents: .date)
                        .tsFont(.footnote)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
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

#Preview {
    NavigationStack {
        ReceiptComposeView(viewModel: DIContainer.preview().makeReceiptComposeViewModel(user: AuthUser(id: 5, name: "이시우", roles: [.fa])))
    }
}
