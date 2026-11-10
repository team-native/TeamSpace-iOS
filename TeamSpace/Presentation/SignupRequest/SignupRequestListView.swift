import SwiftUI

/// 가입 요청 관리 [Admin] — 검토 중 · 처리됨, 요청마다 승인 (서버에 거절은 없어요)
struct SignupRequestListView: View {
    @State private var viewModel: SignupRequestListViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: SignupRequestListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "가입 요청", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .tsToast($viewModel.toastMessage)
        .sheet(item: $viewModel.approvingRequest) { request in
            SignupApproveSheet(viewModel: viewModel, request: request)
                .presentationDetents([.height(500)])
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView()
        case .empty, .forbidden:
            InfoBanner(message: "관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            TSSegmentedControl(
                items: SignupRequestListViewModel.Filter.allCases,
                selection: viewModel.filter,
                title: { "\($0.title) \(viewModel.count(of: $0))" },
                onSelect: { viewModel.filter = $0 }
            )
            if viewModel.requests.isEmpty {
                InfoBanner(message: viewModel.filter == .pending ? "검토할 가입 요청이 없어요." : "처리한 가입 요청이 없어요.", style: .muted)
            }
            ForEach(viewModel.requests) { request in
                SignupRequestCard(request: request) { Task { await viewModel.startApproval(request) } }
            }
        }
    }
}

/// 가입 요청 한 건 — 이름 · 이메일 · 부서 · 남긴 말
private struct SignupRequestCard: View {
    let request: SignupRequestItem
    let onApprove: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(request.metaText)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                Spacer(minLength: Spacing.sm)
                Text(request.statusText)
                    .tsFont(.caption2)
                    .foregroundStyle(request.status == .reviewing ? Color.tsPrimary : Color.tsInk3)
            }
            WorkspaceItemText(title: request.name, meta: request.email)
            if let message = request.message {
                Text(message)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if request.status == .reviewing {
                Button("승인하기", action: onApprove)
                    .buttonStyle(.tsPrimary)
            }
        }
    }
}

/// 승인 시트 — 조직도 구성원 · 초기 비밀번호는 선택
private struct SignupApproveSheet: View {
    @Bindable var viewModel: SignupRequestListViewModel
    let request: SignupRequestItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(request.name)님 계정을 만들까요?")
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                Text("\(request.email) · \(request.department) 구성원으로 등록돼요. 승인 메일이 함께 가요.")
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            memberPicker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                TSTextField(
                    label: "초기 비밀번호 (선택)", placeholder: "비우면 요청할 때 정한 비밀번호", text: $viewModel.temporaryPassword,
                    isSecure: true, hasError: viewModel.passwordHint != nil, textContentType: .newPassword
                )
                if let hint = viewModel.passwordHint {
                    Text(hint)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsNegative)
                }
            }
            Spacer(minLength: 0)
            Button("승인") { Task { await viewModel.approve() } }
                .buttonStyle(.tsPrimaryLarge)
                .disabled(!viewModel.canApprove)
        }
        .padding(Spacing.screen)
        .background(Color.tsBackground.ignoresSafeArea())
    }

    /// 조직도의 누구인지 — 계정이 아직 없는 사람만 보여요.
    private var memberPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("조직도 구성원")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            Menu {
                Button("연결 안 함") { viewModel.selectedMemberId = nil }
                ForEach(viewModel.linkableMembers) { member in
                    Button(SignupRequestListViewModel.memberText(member)) { viewModel.selectedMemberId = member.id }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedMemberText)
                        .tsFont(.body)
                        .foregroundStyle(viewModel.selectedMember == nil ? Color.tsInk3 : Color.tsInk)
                    Spacer(minLength: Spacing.sm)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(Color.tsInk3)
                }
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: 52)
                .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            .accessibilityLabel("조직도 구성원, \(viewModel.selectedMemberText)")
            Text(viewModel.linkableMembers.isEmpty ? "연결할 수 있는 구성원이 없어요." : "같은 이름이라도 한 번 더 확인해 주세요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

#Preview {
    NavigationStack {
        SignupRequestListView(
            viewModel: DIContainer.preview().makeSignupRequestListViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin]))
        )
    }
}
