import SwiftUI

/// 멤버 관리 [Admin] — 검색 · 사람마다 역할 · 부서 · 계정 켜기/끄기 · 조직도 연결 · 삭제, 멤버 추가
struct MemberAdminView: View {
    @State private var viewModel: MemberAdminViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MemberAdminViewModel) {
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
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "멤버 관리", onBack: { dismiss() }) {
                if viewModel.state.value != nil {
                    Button("추가") { viewModel.startAdd() }
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsPrimary)
                        .accessibilityLabel("멤버 추가")
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .tsToast($viewModel.toastMessage)
        .sheet(isPresented: Binding(
            get: { viewModel.editingMemberId != nil },
            set: { if !$0 { viewModel.editingMemberId = nil } }
        )) {
            MemberEditSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.isAddPresented) {
            MemberAddSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .alert(
            "임시 비밀번호",
            isPresented: Binding(get: { viewModel.createdMember != nil }, set: { if !$0 { viewModel.createdMember = nil } }),
            presenting: viewModel.createdMember
        ) { created in
            Button("복사하고 닫기") { UIPasteboard.general.string = created.temporaryPassword }
            Button("닫기", role: .cancel) {}
        } message: { created in
            Text("\(created.member.name)님 계정을 만들었어요.\n\(created.temporaryPassword)\n\n이 비밀번호는 지금만 볼 수 있어요. 안전한 방법으로 전해 주세요.")
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
            InfoBanner(message: "역할은 한 사람에 하나예요. FA 는 재정 권한 화면에서 따로 줘요. 끈 계정은 로그인할 수 없어요.", style: .muted)
            SearchField(placeholder: "이름, 이메일, 부서 검색", text: $viewModel.query)
            Text(viewModel.summaryText)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk3)
            if viewModel.members.isEmpty {
                InfoBanner(message: "검색 결과가 없어요.", style: .muted)
            } else {
                WorkspaceCard {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        if index > 0 { TSDivider() }
                        MemberAdminRow(member: member, isMe: viewModel.isMe(member)) {
                            viewModel.editingMemberId = member.id
                        }
                    }
                }
            }
        }
    }
}

/// 한 사람 — 이름 · 부서 · 역할 · 이메일, 꺼진 계정은 흐리게
private struct MemberAdminRow: View {
    let member: ManagedMember
    let isMe: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(member.name + (isMe ? " (나)" : ""))
                            .tsFont(.calloutBold)
                            .foregroundStyle(Color.tsInk)
                        if !member.isActive {
                            Text("꺼짐")
                                .tsFont(.caption2)
                                .foregroundStyle(Color.tsNegative)
                        } else if !member.isLinked {
                            Text("조직도 미연결")
                                .tsFont(.caption2)
                                .foregroundStyle(Color.tsInk3)
                        }
                    }
                    Text(member.metaText)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                    Text(member.email)
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
                Spacer(minLength: Spacing.sm)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
            .opacity(member.isActive ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("역할 · 부서 · 계정 상태를 바꿔요")
    }
}

/// 한 사람 편집 — 바꾸면 바로 저장돼요.
private struct MemberEditSheet: View {
    @Bindable var viewModel: MemberAdminViewModel
    @State private var isDeleteConfirmPresented = false

    var body: some View {
        ScrollView {
            if let member = viewModel.editingMember {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(member.name)
                            .tsFont(.title3)
                            .foregroundStyle(Color.tsInk)
                        Text(member.email)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk3)
                    }
                    MemberMenuField(
                        label: "역할",
                        value: member.primaryRole.title,
                        options: ManagedMember.assignableRoles.map { ($0.title, $0) },
                        onSelect: { role in Task { await viewModel.changeRole(member, to: role) } }
                    )
                    if member.primaryRole == .fa {
                        Text("지금 FA 예요. 여기서 역할을 바꾸면 FA 가 빠져요.")
                            .tsFont(.caption)
                            .foregroundStyle(Color.tsInk3)
                    }
                    MemberMenuField(
                        label: "부서",
                        value: member.department.isEmpty ? "미지정" : member.department,
                        options: viewModel.departmentOptions.map { ($0, $0) },
                        onSelect: { dept in Task { await viewModel.changeDepartment(member, to: dept) } }
                    )
                    Toggle(isOn: Binding(
                        get: { member.isActive },
                        set: { isOn in Task { await viewModel.setActive(member, to: isOn) } }
                    )) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("계정 켜기")
                                .tsFont(.footnoteBold)
                                .foregroundStyle(Color.tsInk)
                            Text(viewModel.isMe(member) ? "내 계정은 끌 수 없어요" : "끄면 로그인할 수 없어요. 기록은 남아요.")
                                .tsFont(.caption)
                                .foregroundStyle(Color.tsInk3)
                        }
                    }
                    .tint(Color.tsPrimary)
                    .disabled(viewModel.isMe(member))
                    linkSection(member)
                    if !viewModel.isMe(member) {
                        Button("계정 삭제", role: .destructive) { isDeleteConfirmPresented = true }
                            .buttonStyle(.tsSecondary)
                            .confirmationDialog(
                                "\(member.name)님 계정을 삭제할까요?",
                                isPresented: $isDeleteConfirmPresented,
                                titleVisibility: .visible
                            ) {
                                Button("삭제", role: .destructive) { Task { await viewModel.delete(member) } }
                            } message: {
                                Text("되돌릴 수 없어요. 잠시 막기만 하려면 계정을 꺼 주세요.")
                            }
                    }
                }
                .disabled(viewModel.processingId == member.id)
                .padding(Spacing.screen)
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
    }

    /// 계정이 없는 조직도 구성원 중에서 골라 이어요. 이미 이어진 계정은 다른 구성원으로 바꿀 수 있어요.
    @ViewBuilder
    private func linkSection(_ member: ManagedMember) -> some View {
        if member.hasAccount {
            let candidates = viewModel.unlinkedOrganizationMembers
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(member.isLinked ? "조직도 연결 바꾸기" : "조직도 연결")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                if candidates.isEmpty {
                    Text("연결할 수 있는 조직도 구성원이 없어요.")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                } else {
                    Menu {
                        ForEach(candidates) { candidate in
                            Button([candidate.name, candidate.department].filter { !$0.isEmpty }.joined(separator: " · ")) {
                                Task { await viewModel.link(member, to: candidate) }
                            }
                        }
                    } label: {
                        MemberMenuLabel(text: "조직도에서 고르기", isPlaceholder: true)
                    }
                    Text("같은 이름이라도 한 번 더 확인해 주세요. 고르면 바로 연결돼요.")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
            }
        }
    }
}

/// 멤버 추가 — 이름 · 이메일 · 부서 · 역할
private struct MemberAddSheet: View {
    @Bindable var viewModel: MemberAdminViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("멤버 추가")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                    Text("임시 비밀번호가 만들어져요. 다 만들면 한 번만 보여줘요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
                TSTextField(label: "이름", placeholder: "홍길동", text: $viewModel.draft.name, textContentType: .name)
                TSTextField(
                    label: "이메일", placeholder: "name@gsm.hs.kr", text: $viewModel.draft.email,
                    keyboardType: .emailAddress, textContentType: .emailAddress
                )
                MemberMenuField(
                    label: "부서",
                    value: viewModel.draft.department.isEmpty ? "미지정" : viewModel.draft.department,
                    options: [("미지정", "")] + viewModel.departmentOptions.map { ($0, $0) },
                    onSelect: { viewModel.draft.department = $0 }
                )
                MemberMenuField(
                    label: "역할",
                    value: viewModel.draft.role.title,
                    options: ManagedMember.assignableRoles.map { ($0.title, $0) },
                    onSelect: { viewModel.draft.role = $0 }
                )
                Button("추가") { Task { await viewModel.create() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canCreate)
            }
            .padding(Spacing.screen)
        }
        .background(Color.tsBackground.ignoresSafeArea())
    }
}

/// 라벨 + 메뉴로 고르는 칸 (TSTextField 와 같은 모양)
private struct MemberMenuField<Value: Hashable>: View {
    let label: String
    let value: String
    let options: [(String, Value)]
    let onSelect: (Value) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            Menu {
                ForEach(options, id: \.1) { option in
                    Button(option.0) { onSelect(option.1) }
                }
            } label: {
                MemberMenuLabel(text: value, isPlaceholder: false)
            }
            .accessibilityLabel("\(label), \(value)")
        }
    }
}

private struct MemberMenuLabel: View {
    let text: String
    let isPlaceholder: Bool

    var body: some View {
        HStack {
            Text(text)
                .tsFont(.body)
                .foregroundStyle(isPlaceholder ? Color.tsInk3 : Color.tsInk)
            Spacer(minLength: Spacing.sm)
            Image(systemName: "chevron.up.chevron.down")
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: 52)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        MemberAdminView(
            viewModel: DIContainer.preview().makeMemberAdminViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin]))
        )
    }
}
