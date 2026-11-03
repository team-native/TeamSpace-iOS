import SwiftUI

/// 모집 자리 관리 [Admin] — 자리 목록 · 추가 · 수정 시트 · 삭제 · 저장
struct ProjectOpeningsView: View {
    @State private var viewModel: ProjectOpeningsViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ProjectOpeningsViewModel) {
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
            TSNavigationBar(title: "모집 자리 관리", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.state.value != nil, viewModel.canManage {
                Button(viewModel.saveTitle) { Task { await viewModel.save() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSave)
                    .padding(.horizontal, Spacing.screen)
                    .padding(.vertical, Spacing.md)
                    .background(Color.tsBackground)
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { if viewModel.state.value == nil { await viewModel.load() } }
        .sheet(item: $viewModel.editing) { _ in
            OpeningEditSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .alert("모집 자리를 저장했어요", isPresented: $viewModel.didSave) {
            Button("확인") { dismiss() }
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
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            InfoBanner(message: "프로젝트를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
        case .loaded:
            if !viewModel.canManage {
                InfoBanner(message: "모집 자리는 관리자만 바꿀 수 있어요.", icon: .lock, style: .muted)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.projectName)
                    .tsFont(.title3)
                    .foregroundStyle(Color.tsInk)
                Text(viewModel.summaryText)
                    .tsFont(.footnote)
                    .foregroundStyle(Color.tsInk3)
            }
            ForEach(viewModel.openings) { opening in
                OpeningRow(
                    opening: opening,
                    isEditable: viewModel.canManage,
                    onEdit: { viewModel.startEditing(opening) },
                    onRemove: { viewModel.remove(opening) }
                )
            }
            if viewModel.canManage {
                Button("모집 자리 추가") { viewModel.startAdding() }
                    .buttonStyle(.tsSecondary)
                InfoBanner(message: "자리를 모두 지우고 저장하면 모집이 마감돼요. 이미 받은 신청은 그대로 남아요.", style: .muted)
            }
        }
    }
}

/// 자리 한 개 — 직군 · 이름 · 인원 · 기간 · 설명, 수정 · 삭제
private struct OpeningRow: View {
    let opening: OpeningDraft
    let isEditable: Bool
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        WorkspaceCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(opening.role)
                        .tsFont(.caption2Bold)
                        .foregroundStyle(Color.tsPrimary)
                    Text(opening.summaryText)
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsInk)
                    if !opening.description.isEmpty {
                        Text(opening.description)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: Spacing.sm)
                if isEditable {
                    CircleIconButton(icon: .pencil, accessibilityLabel: "\(opening.displayTitle) 고치기", size: 32, action: onEdit)
                    CircleIconButton(icon: .close, accessibilityLabel: "\(opening.displayTitle) 지우기", size: 32, action: onRemove)
                }
            }
        }
    }
}

/// 자리 추가 · 수정 시트
private struct OpeningEditSheet: View {
    @Bindable var viewModel: ProjectOpeningsViewModel

    var body: some View {
        if viewModel.editing != nil {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text(viewModel.isEditingNew ? "모집 자리 추가" : "모집 자리 수정")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                    HStack(spacing: Spacing.md) {
                        ComposeField(label: "직군") {
                            TextField("예) iOS", text: binding(\.role))
                                .tsFont(.callout)
                        }
                        ComposeField(label: "자리 이름 (선택)") {
                            TextField("예) iOS 개발", text: binding(\.title))
                                .tsFont(.callout)
                        }
                    }
                    WorkspaceCard {
                        Stepper(value: binding(\.headcount), in: OpeningDraft.headcountRange) {
                            Text("모집 인원 \(viewModel.editing?.headcount ?? 1)명")
                                .tsFont(.footnoteBold)
                        }
                        TSDivider()
                        DatePicker("모집 시작", selection: binding(\.startDate), displayedComponents: .date)
                            .tsFont(.footnote)
                        TSDivider()
                        DatePicker("모집 마감", selection: binding(\.endDate), displayedComponents: .date)
                            .tsFont(.footnote)
                    }
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        PostComposeLabel(
                            title: "하는 일",
                            trailing: "\(viewModel.editing?.description.count ?? 0) / \(OpeningDraft.descriptionLimit)"
                        )
                        TextEditor(text: binding(\.description))
                            .tsFont(.callout)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(Spacing.md)
                            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                            .accessibilityLabel("하는 일")
                    }
                    if let hint = viewModel.editingHint {
                        Text(hint)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsNegative)
                    }
                    Button(viewModel.isEditingNew ? "추가" : "적용") { viewModel.applyEditing() }
                        .buttonStyle(.tsPrimaryLarge)
                        .disabled(!viewModel.canApplyEditing)
                }
                .padding(Spacing.screen)
            }
            .background(Color.tsBackground.ignoresSafeArea())
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<OpeningDraft, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel.editing?[keyPath: keyPath] ?? OpeningDraft()[keyPath: keyPath] },
            set: { viewModel.editing?[keyPath: keyPath] = $0 }
        )
    }
}

#Preview {
    NavigationStack {
        ProjectOpeningsView(
            viewModel: DIContainer.preview().makeProjectOpeningsViewModel(
                projectId: "book-on", user: AuthUser(id: 1, name: "관리자", roles: [.admin])
            )
        )
    }
}
