import SwiftUI

/// 01-5 소속 부서 선택 — 시스템 Menu 로 표시
struct DepartmentMenuField: View {
    let departments: [Department]
    let selection: Department?
    let onSelect: (Department) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("소속 부서")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            Menu {
                ForEach(departments, id: \.self) { department in
                    Button {
                        onSelect(department)
                    } label: {
                        if department == selection {
                            Label(department.displayName, systemImage: TSIcon.check.rawValue)
                        } else {
                            Text(department.displayName)
                        }
                    }
                }
            } label: {
                menuLabel
            }
            .accessibilityLabel("소속 부서, \(selection?.displayName ?? "선택 안 됨")")
        }
    }

    private var menuLabel: some View {
        HStack(spacing: Spacing.sm) {
            Text(selection?.displayName ?? "부서를 선택해 주세요")
                .tsFont(.body)
                .foregroundStyle(selection == nil ? Color.tsInk3 : Color.tsInk)
            Spacer()
            TSIcon.chevronDown.image
                .tsIconSize(.lg)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: 52)
        .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

#Preview {
    DepartmentMenuField(departments: Department.selectable, selection: .design, onSelect: { _ in })
        .padding()
}
