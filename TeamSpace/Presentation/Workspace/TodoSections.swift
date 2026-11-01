import SwiftUI

/// 07-2 상단 제목
struct TodoHeader: View {
    let dateLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("오늘 할 일을 한 눈에 볼 수 있어요")
                .tsFont(.micro)
                .foregroundStyle(Color.tsPrimary)
            Text("오늘의 할 일을 정리해요")
                .tsFont(.title3)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(dateLine)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 07-2 오늘 · 예정 · 완료 칩 — 누르면 그 섹션으로 이동해요.
struct TodoKindChips: View {
    let viewModel: TodoListViewModel
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(TodoSection.Kind.allCases.enumerated()), id: \.offset) { index, kind in
                let isFirst = index == 0
                Button {
                    if let id = viewModel.firstSectionId(of: kind) { onSelect(id) }
                } label: {
                    Text("\(kind.title) \(viewModel.count(of: kind))")
                        .tsFont(.caption2Bold)
                        .foregroundStyle(isFirst ? Color.tsOnPrimary : Color.tsInk2)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 28)
                        .background(isFirst ? Color.tsPrimary : Color.tsSurface2, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 섹션 제목 + 할 일 카드들
struct TodoSectionView: View {
    let section: TodoSection
    let onToggle: (TodoItem) -> Void
    let onOpen: (AppRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(section.title)
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if section.kind == .today {
                    Text("미완료 \(section.items.count)개")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk2)
                }
            }
            ForEach(section.items) { todo in
                TodoCard(todo: todo, onToggle: { onToggle(todo) }, onOpen: onOpen)
            }
        }
    }
}

/// 할 일 카드 — 체크 박스 · 제목 · 설명 · 상태 · 연결 링크
struct TodoCard: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onOpen: (AppRoute) -> Void

    var body: some View {
        WorkspaceCard {
            HStack(alignment: .top, spacing: Spacing.md) {
                TodoCheckBox(isOn: todo.isDone, action: onToggle)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(todo.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(todo.isDone ? Color.tsInk3 : Color.tsInk)
                    Text(todo.metaText())
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk2)
                }
            }
            StatusBadge(
                title: todo.badgeTitle(),
                tone: todo.isDone ? .neutral : .primary,
                icon: todo.isDone ? .check : .circle
            )
            if let linkTitle = todo.linkTitle, let route = todo.linkRoute {
                WorkspaceLinkRow(title: linkTitle) { onOpen(route) }
            }
        }
    }
}

/// 둥근 사각 체크 박스 (28pt)
struct TodoCheckBox: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(isOn ? Color.tsPrimary : Color.tsSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .stroke(isOn ? Color.clear : Color.tsLine, lineWidth: 1.5)
                )
                .overlay {
                    if isOn {
                        TSIcon.check.sized(.md, weight: .bold)
                            .foregroundStyle(Color.tsOnPrimary)
                    }
                }
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "완료 취소" : "완료로 표시")
    }
}

/// 날짜만 고르는 시트
struct TodoDatePickerSheet: View {
    @Binding var date: Date
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.md) {
            DatePicker("날짜", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.tsPrimary)
                .environment(\.locale, Locale(identifier: "ko_KR"))
            Button("완료") {
                onDone()
                dismiss()
            }
            .buttonStyle(.tsPrimary)
        }
        .padding(Spacing.xl)
        .background(Color.tsSurface)
    }
}
