import SwiftUI

/// 07-2 나의 To-do
struct TodoListView: View {
    @State private var viewModel: TodoListViewModel
    private let onNavigate: (AppRoute) -> Void

    @FocusState private var isTitleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    static let quickAddId = "quickAdd"

    init(viewModel: TodoListViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    TodoHeader(dateLine: viewModel.dateLine)
                    TodoKindChips(viewModel: viewModel) { id in
                        withAnimation { proxy.scrollTo(id, anchor: .top) }
                    }
                    Button {
                        withAnimation { proxy.scrollTo(Self.quickAddId, anchor: .top) }
                        isTitleFocused = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            TSIcon.plus.sized(.base, weight: .bold)
                            Text("할 일 추가")
                        }
                    }
                    .buttonStyle(.tsPrimary)
                    content
                }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.xxxl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "나의 To-do", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(TodoListAlerts(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 200)
        case .empty, .forbidden:
            InfoBanner(message: "할 일을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            ForEach(viewModel.sections) { section in
                TodoSectionView(
                    section: section,
                    onToggle: { todo in Task { await viewModel.toggle(todo) } },
                    onOpen: onNavigate
                )
                .id(section.id)
            }
            InfoBanner(
                message: "알림 읽음은 할 일 완료가 아니에요. 연결된 업무가 있어도 수동으로 할 일을 완료하면 To-do만 바뀌며, 연결된 결재를 승인하지 않아요.",
                icon: .infoCircle,
                style: .muted
            )
            TodoQuickAddCard(viewModel: viewModel, isTitleFocused: $isTitleFocused)
                .id(Self.quickAddId)
        }
    }
}

/// 날짜 선택 시트 · 오류 알림
private struct TodoListAlerts: ViewModifier {
    @Bindable var viewModel: TodoListViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isDatePickerPresented) {
                TodoDatePickerSheet(date: $viewModel.newDueDate) { viewModel.hasPickedDate = true }
                    .presentationDetents([.height(460)])
            }
            .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
                Button("확인", role: .cancel) {}
            }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        TodoListView(viewModel: DIContainer.preview().makeTodoListViewModel(userName: "옥물결"), onNavigate: { _ in })
    }
}
