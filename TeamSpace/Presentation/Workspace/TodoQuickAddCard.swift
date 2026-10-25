import SwiftUI

/// 07-2 빠르게 추가 — 제목 · 날짜 · 프로젝트 · 업무 연결
struct TodoQuickAddCard: View {
    @Bindable var viewModel: TodoListViewModel
    var isTitleFocused: FocusState<Bool>.Binding

    var body: some View {
        WorkspaceCard {
            Text("빠르게 추가")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            TextField("새 할 일 제목을 입력해 주세요", text: $viewModel.newTitle)
                .focused(isTitleFocused)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk)
                .submitLabel(.done)
                .onSubmit { Task { await viewModel.add() } }
                .padding(.horizontal, Spacing.md)
                .frame(height: 44)
                .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            HStack(spacing: Spacing.xs) {
                Button { viewModel.isDatePickerPresented = true } label: {
                    TodoOptionChip(title: viewModel.dateChipTitle, isSelected: viewModel.hasPickedDate)
                }
                .buttonStyle(.plain)
                projectMenu
                linkMenu
            }
            Button("할 일 추가") { Task { await viewModel.add() } }
                .buttonStyle(.tsPrimary)
                .disabled(!viewModel.canAdd)
        }
    }

    private var projectMenu: some View {
        Menu {
            Button("연결 안 함") { viewModel.newProjectName = nil }
            ForEach(viewModel.projectNames, id: \.self) { name in
                Button(name) { viewModel.newProjectName = name }
            }
        } label: {
            TodoOptionChip(title: viewModel.newProjectName ?? "프로젝트 연결", isSelected: viewModel.newProjectName != nil)
        }
    }

    private var linkMenu: some View {
        Menu {
            ForEach(TodoLinkKind.selectable, id: \.self) { kind in
                Button(kind.title) { viewModel.newLinkKind = kind }
            }
        } label: {
            TodoOptionChip(
                title: viewModel.newLinkKind == .manual ? "업무 연결" : viewModel.newLinkKind.title,
                isSelected: viewModel.newLinkKind != .manual
            )
        }
    }
}

/// 빠르게 추가의 작은 선택 칩
private struct TodoOptionChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .tsFont(.caption2Bold)
            .foregroundStyle(isSelected ? Color.tsPrimary : Color.tsInk2)
            .padding(.horizontal, Spacing.md)
            .frame(height: 28)
            .background(isSelected ? Color.tsPrimarySoft : Color.tsSurface2, in: Capsule())
    }
}
