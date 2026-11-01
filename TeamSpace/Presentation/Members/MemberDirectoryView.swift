import SwiftUI

/// 03 팀원 소개 — 02-3 목록 / 02-5 조직도
struct MemberDirectoryView: View {
    @State private var viewModel: MemberDirectoryViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MemberDirectoryViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ScreenTitle(title: title, subtitle: subtitle)
                if viewModel.mode == .list {
                    SearchField(placeholder: "이름, 부서, 역할로 검색", text: $viewModel.query)
                }
                TSSegmentedControl(
                    items: MemberDirectoryMode.allCases,
                    selection: viewModel.mode,
                    title: { $0.title },
                    onSelect: { viewModel.mode = $0 }
                )
                switch viewModel.mode {
                case .list:
                    MemberListContent(viewModel: viewModel, onSelect: open)
                case .organization:
                    OrganizationContent(
                        state: viewModel.organizationState,
                        onSelectDepartment: { viewModel.showMembers(of: $0) },
                        onSelectMember: open,
                        onRetry: { Task { await viewModel.loadOrganizationIfNeeded() } }
                    )
                }
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "팀원 소개", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onChange(of: viewModel.mode) { _, mode in
            if mode == .organization { Task { await viewModel.loadOrganizationIfNeeded() } }
        }
    }

    private var title: String {
        viewModel.mode == .list ? "함께하는 사람들" : "Native 조직도"
    }

    private var subtitle: String {
        viewModel.mode == .list ? viewModel.summary : "부서를 누르면 구성원을 볼 수 있어요."
    }

    private func open(_ member: Member) {
        onNavigate(.memberDetail(id: member.id))
    }
}

/// 02-3 목록 — 부서 칩 · 새 멤버 · 팀원 목록 · 더 보기
private struct MemberListContent: View {
    @Bindable var viewModel: MemberDirectoryViewModel
    let onSelect: (Member) -> Void

    var body: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "볼 수 있는 팀원이 없어요.", icon: .infoCircle, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            FilterChipBar(
                items: viewModel.departmentFilters,
                selection: viewModel.departmentFilter,
                title: { viewModel.title(for: $0) },
                onSelect: { viewModel.departmentFilter = $0 }
            )
            if viewModel.query.isEmpty, viewModel.departmentFilter == .all, let member = viewModel.newMember() {
                NewMemberSpotlight(member: member) { onSelect(member) }
            }
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.filteredMembers.isEmpty {
            InfoBanner(message: "‘\(viewModel.query)’에 맞는 팀원이 없어요. 이름이나 부서를 다시 확인해 주세요.", icon: .infoCircle, style: .muted)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.visibleMembers) { member in
                    Button { onSelect(member) } label: { MemberRow(member: member) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xxs)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
            if viewModel.hiddenCount > 0 {
                Button("\(viewModel.hiddenCount)명 더 보기") { viewModel.isExpanded = true }
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsPrimary)
                    .frame(maxWidth: .infinity, minHeight: 49)
                    .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.cardLarge, style: .continuous))
                    .buttonStyle(.plain)
            }
        }
    }
}

/// 이번 주 새 멤버
private struct NewMemberSpotlight: View {
    let member: Member
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                AvatarView(size: 43)
                VStack(alignment: .leading, spacing: Spacing.compact) {
                    Text("이번 주 새 멤버")
                        .tsFont(.caption2Bold)
                        .foregroundStyle(Color.tsPrimary)
                    Text("\(member.name) 님이 \(member.department.directoryName)에 합류했어요")
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsInk)
                    Text("반갑게 인사해 주세요 👋")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.lg)
            .background(TSGradient.notificationPreview, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// 불러오기 실패 + 다시 시도
struct RetryView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(message)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .multilineTextAlignment(.center)
            Button("다시 시도", action: onRetry)
                .buttonStyle(.ts(.secondary, size: .small, fullWidth: false))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    NavigationStack {
        MemberDirectoryView(viewModel: DIContainer.preview().makeMemberDirectoryViewModel(), onNavigate: { _ in })
    }
}
