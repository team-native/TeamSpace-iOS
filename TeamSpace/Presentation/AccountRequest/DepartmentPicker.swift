import SwiftUI

/// 01-2 소속 부서 입력칸 — 누르면 01-5 선택 카드가 열립니다.
struct DepartmentSelectField: View {
    let selection: Department?
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("소속 부서")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
            Button(action: onTap) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("소속 부서, \(selection?.displayName ?? "선택 안 됨")")
            .accessibilityHint("눌러서 부서를 선택해요")
        }
    }
}

/// 01-5 소속 부서 선택 (iOS Menu) — 화면 아래쪽 카드 + 옅은 딤
struct DepartmentPickerOverlay: View {
    let departments: [Department]
    let selection: Department?
    let onSelect: (Department) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tsScrim
                .opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("닫기")
                .accessibilityAddTraits(.isButton)
            VStack(spacing: 0) {
                ForEach(Array(departments.enumerated()), id: \.element) { index, department in
                    if index > 0 { TSDivider() }
                    DepartmentRow(department: department, isSelected: department == selection) {
                        onSelect(department)
                    }
                }
            }
            .background(Color.tsSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .tsShadow(.raised)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct DepartmentRow: View {
    let department: Department
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    if isSelected {
                        TSIcon.check.image
                            .tsIconSize(.md, weight: .bold)
                            .foregroundStyle(Color.tsPrimary)
                    }
                }
                .frame(width: 20, height: 20)
                Text(department.displayName)
                    .tsFont(isSelected ? .subheadline : .bodyLarge)
                    .foregroundStyle(isSelected ? Color.tsPrimary : Color.tsInk)
                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .frame(height: 52)
            .background(isSelected ? Color.tsPrimarySoft : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    Color.tsBackground
        .overlay {
            DepartmentPickerOverlay(departments: Department.selectable, selection: .design, onSelect: { _ in }, onDismiss: {})
        }
}
