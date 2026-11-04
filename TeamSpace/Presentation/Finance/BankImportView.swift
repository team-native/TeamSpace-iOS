import SwiftUI

/// 은행 거래 확인 · 반영 [FA · Admin] — 확인할 거래 · 반영 대기 · 끝난 거래
struct BankImportView: View {
    @State private var viewModel: BankImportViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BankImportViewModel) {
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
            TSNavigationBar(title: "은행 거래", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .tsToast($viewModel.toastMessage)
        .sheet(item: $viewModel.linkingItem) { item in
            BankImportLinkSheet(item: item, viewModel: viewModel)
                .presentationDetents([.medium, .large])
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
            InfoBanner(message: "FA · 관리자만 볼 수 있는 화면이에요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if let account = viewModel.account {
                BankAccountCard(
                    account: account,
                    detail: viewModel.accountDetailText,
                    failureNotice: viewModel.failureNotice,
                    isSyncing: viewModel.isSyncing,
                    onSync: { Task { await viewModel.sync() } }
                )
            }
            InfoBanner(message: "은행에서 불러온 거래를 확인하면 반영 대기로 옮겨져요. 반영하면 입금은 수금, 출금은 지출로 재정에 들어가요.", style: .muted)
            TSSegmentedControl(
                items: BankImportViewModel.Filter.allCases,
                selection: viewModel.filter,
                title: { "\($0.rawValue) \(viewModel.count($0))" },
                onSelect: { viewModel.filter = $0 }
            )
            if viewModel.filter == .confirmed, viewModel.canCommit {
                WorkspaceCard {
                    Text(viewModel.confirmedTotalText)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk2)
                    Button(viewModel.commitTitle) { Task { await viewModel.commit() } }
                        .buttonStyle(.tsPrimary)
                        .disabled(!viewModel.canCommit)
                }
            }
            if viewModel.items.isEmpty {
                InfoBanner(message: "\(viewModel.filter.rawValue)가 없어요.", style: .muted)
            } else {
                ForEach(viewModel.items) { item in
                    BankImportCard(
                        item: item,
                        isProcessing: viewModel.processingId == item.id,
                        onReview: { action in Task { await viewModel.review(item, action) } },
                        onLink: { viewModel.startLinking(item) }
                    )
                }
            }
        }
    }
}

/// 거래 한 줄 — 상대 · 금액 · 날짜 · 연결 계약 · 확인/제외
private struct BankImportCard: View {
    let item: BankImport
    let isProcessing: Bool
    let onReview: (ReviewBankImportUseCase.Action) -> Void
    let onLink: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack {
                Text(item.direction.rawValue)
                    .tsFont(.caption2Bold)
                    .foregroundStyle(item.direction == .inbound ? Color.tsPositive : Color.tsNegative)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(item.direction == .inbound ? Color.tsPositiveSoft : Color.tsNegativeSoft, in: Capsule())
                Spacer(minLength: Spacing.sm)
                Text(item.status.rawValue)
                    .tsFont(.caption2)
                    .foregroundStyle(item.status.isOpen ? Color.tsPrimary : Color.tsInk3)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(item.counterparty.isEmpty ? "상대 없음" : item.counterparty)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Spacer(minLength: Spacing.sm)
                Text(item.amountText)
                    .tsFont(.calloutBold)
                    .foregroundStyle(item.direction == .inbound ? Color.tsPositive : Color.tsInk)
            }
            Text("\(TSFormat.dateTime(item.date)) · \(item.matchText)")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk3)
            if let committedAt = item.committedAt {
                Text("\(TSFormat.dateTime(committedAt)) \(item.committedBy ?? "") 반영")
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
            if item.status.isOpen {
                HStack(spacing: Spacing.sm) {
                    if item.direction == .inbound {
                        Button(item.matchedProject?.isEmpty == false ? "연결 바꾸기" : "계약 연결", action: onLink)
                            .buttonStyle(.ts(.secondary, size: .small))
                    }
                    Button("제외") { onReview(.exclude) }
                        .buttonStyle(.ts(.secondary, size: .small))
                    Button("확인") { onReview(.confirm) }
                        .buttonStyle(.ts(.primary, size: .small))
                        .disabled(!item.canConfirm)
                }
                .disabled(isProcessing)
            } else if item.status == .confirmed {
                Button("확인 취소") { onReview(.unconfirm) }
                    .buttonStyle(.ts(.secondary, size: .small))
                    .disabled(isProcessing)
            }
        }
    }
}

/// 계좌 연동 상태 · 새 거래 불러오기
private struct BankAccountCard: View {
    let account: BankAccountStatus
    let detail: String?
    let failureNotice: String?
    let isSyncing: Bool
    let onSync: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack(alignment: .firstTextBaseline) {
                Text(account.title)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Spacer(minLength: Spacing.sm)
                Text(account.connectionText)
                    .tsFont(.caption2)
                    .foregroundStyle(account.connectionStatus == "connected" ? Color.tsPositive : Color.tsInk3)
            }
            if let detail {
                Text(detail)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            if let failureNotice {
                Text(failureNotice)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsNegative)
            }
            Button {
                onSync()
            } label: {
                if isSyncing {
                    ProgressView()
                } else {
                    Text("새 거래 불러오기")
                }
            }
            .buttonStyle(.ts(.secondary, size: .small))
            .disabled(isSyncing || !account.canSync)
        }
    }
}

/// 입금 → 수주 계약 연결 (프로젝트 이름으로 찾아요)
private struct BankImportLinkSheet: View {
    let item: BankImport
    let viewModel: BankImportViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(item.counterparty.isEmpty ? "상대 없음" : item.counterparty) \(item.amountText)")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                }
                Section("연결할 수주 계약") {
                    switch viewModel.linkableContracts {
                    case .idle, .loading:
                        ProgressView()
                    case .empty, .forbidden:
                        Text("연결할 수주 계약이 없어요.")
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk3)
                    case .failed(let error):
                        Button(error.userMessage) { Task { await viewModel.loadLinkableContracts() } }
                    case .loaded(let names):
                        ForEach(names, id: \.self) { name in
                            Button {
                                Task { await viewModel.link(item, to: name) }
                            } label: {
                                HStack {
                                    Text(name).foregroundStyle(Color.tsInk)
                                    Spacer()
                                    if item.matchedProject == name {
                                        TSIcon.check.sized(.base).foregroundStyle(Color.tsPrimary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("계약 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { viewModel.linkingItem = nil }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BankImportView(viewModel: DIContainer.preview().makeBankImportViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin])))
    }
}
