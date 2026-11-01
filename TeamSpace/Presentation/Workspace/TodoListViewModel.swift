import Foundation
import Observation

/// 07-2 나의 To-do
@Observable
@MainActor
final class TodoListViewModel {
    private(set) var state: ViewState<[TodoItem]> = .idle
    let userName: String

    // 빠르게 추가
    var newTitle = ""
    var newDueDate = Date()
    var hasPickedDate = false
    var newProjectName: String?
    var newLinkKind: TodoLinkKind = .manual
    var isDatePickerPresented = false
    private(set) var isAdding = false
    var errorMessage: String?

    private let fetchTodosUseCase: FetchTodosUseCase
    private let toggleTodoUseCase: ToggleTodoUseCase
    private let addTodoUseCase: AddTodoUseCase
    private let now: () -> Date

    init(
        userName: String,
        fetchTodosUseCase: FetchTodosUseCase,
        toggleTodoUseCase: ToggleTodoUseCase,
        addTodoUseCase: AddTodoUseCase,
        now: @escaping () -> Date = { Date() }
    ) {
        self.userName = userName
        self.fetchTodosUseCase = fetchTodosUseCase
        self.toggleTodoUseCase = toggleTodoUseCase
        self.addTodoUseCase = addTodoUseCase
        self.now = now
    }

    private var todos: [TodoItem] { state.value ?? [] }
    private var calendar: Calendar { .current }

    /// "2026.10.16 금요일 · 옥물결"
    var dateLine: String {
        "\(TSFormat.fullDate(now())) \(TSFormat.weekday(now())) · \(userName)"
    }

    var sections: [TodoSection] {
        let today = calendar.startOfDay(for: now())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let open = todos.filter { !$0.isDone }
        var result: [TodoSection] = []
        let todayItems = open.filter { $0.dueAt < endOfToday }
        if !todayItems.isEmpty {
            result.append(TodoSection(kind: .today, date: today, items: todayItems))
        }
        let upcoming = Dictionary(grouping: open.filter { $0.dueAt >= endOfToday }) { calendar.startOfDay(for: $0.dueAt) }
        result += upcoming.keys.sorted().map { TodoSection(kind: .upcoming, date: $0, items: upcoming[$0] ?? []) }
        let done = Dictionary(grouping: todos.filter(\.isDone)) { calendar.startOfDay(for: $0.completedAt ?? $0.dueAt) }
        result += done.keys.sorted(by: >).map { TodoSection(kind: .done, date: $0, items: done[$0] ?? []) }
        return result
    }

    func count(of kind: TodoSection.Kind) -> Int {
        sections.filter { $0.kind == kind }.reduce(0) { $0 + $1.items.count }
    }

    /// 칩을 눌렀을 때 이동할 섹션
    func firstSectionId(of kind: TodoSection.Kind) -> String? {
        sections.first { $0.kind == kind }?.id
    }

    /// 프로젝트 연결에서 고를 수 있는 프로젝트 (내 할 일에 나온 프로젝트)
    var projectNames: [String] {
        Array(Set(todos.compactMap(\.projectName))).sorted()
    }

    var dateChipTitle: String {
        hasPickedDate ? TSFormat.shortDate(newDueDate) : "날짜 선택"
    }

    var canAdd: Bool {
        !isAdding && AddTodoUseCase.validationMessage(title: newTitle) == nil
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await fetchTodosUseCase.execute())
        } catch AppError.forbidden {
            state = .forbidden
        } catch {
            AppLog.record(error, context: "workspace.todos.load")
            if state.value == nil { state = .failed(error) }
        }
    }

    /// 체크 박스 — 완료 ↔ 미완료
    func toggle(_ todo: TodoItem) async {
        do {
            replace(try await toggleTodoUseCase.execute(todo))
        } catch {
            AppLog.record(error, context: "workspace.todos.toggle")
            errorMessage = error.userMessage
        }
    }

    func add() async {
        guard canAdd else { return }
        isAdding = true
        defer { isAdding = false }
        let draft = TodoDraft(
            title: newTitle,
            dueAt: hasPickedDate ? newDueDate : now(),
            projectName: newProjectName,
            linkKind: newLinkKind
        )
        do {
            let todo = try await addTodoUseCase.execute(draft)
            state = .loaded((todos + [todo]).sorted { $0.dueAt < $1.dueAt })
            resetDraft()
        } catch {
            AppLog.record(error, context: "workspace.todos.add")
            errorMessage = error.userMessage
        }
    }

    private func replace(_ todo: TodoItem) {
        state = .loaded(todos.map { $0.id == todo.id ? todo : $0 })
    }

    private func resetDraft() {
        newTitle = ""
        newDueDate = now()
        hasPickedDate = false
        newProjectName = nil
        newLinkKind = .manual
    }
}
