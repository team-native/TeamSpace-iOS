import SwiftUI

/// 05-6 프로젝트 인력 지원 (시트)
struct StaffingRequestSheet: View {
    @State private var viewModel: StaffingRequestViewModel
    private let onFinish: (SubmittedDocument?) -> Void

    init(viewModel: StaffingRequestViewModel, onFinish: @escaping (SubmittedDocument?) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ComposeSheetHeader(
                    title: "프로젝트 인력 지원",
                    subtitle: "진행 중인 프로젝트에 필요한 직군과 인원을 요청해요.",
                    onClose: { onFinish(nil) }
                )
                StaffingFormFields(viewModel: viewModel)
                ApprovalLinePreview(approvers: ApprovalLinePreview.defaultLine)
            }
            .padding(.horizontal, Spacing.xxl)
            .padding(.top, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("결재 요청 제출") {
                Task { if let result = await viewModel.submit() { onFinish(result) } }
            }
            .buttonStyle(.tsPrimaryLarge)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, Spacing.xxl)
            .padding(.vertical, Spacing.md)
            .background(Color.tsSurface)
        }
        .background(Color.tsSurface)
        .sheet(isPresented: $viewModel.isPeriodPickerPresented) {
            MonthRangePickerSheet(start: viewModel.startMonth, end: viewModel.endMonth) { start, end in
                viewModel.setPeriod(start: start, end: end)
            }
            .presentationDetents([.height(340)])
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

private struct StaffingFormFields: View {
    @Bindable var viewModel: StaffingRequestViewModel

    var body: some View {
        ComposeField(label: "프로젝트", height: 50) {
            Menu {
                Picker("프로젝트", selection: $viewModel.project) {
                    ForEach(viewModel.projects, id: \.self) { Text($0).tag($0) }
                }
            } label: {
                ComposeValueLabel(value: viewModel.project, placeholder: "선택해 주세요")
            }
        }
        RoleChipRow(selection: $viewModel.role)
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            ComposeField(label: "인원", height: 50) {
                HStack {
                    StepButton(icon: "minus") { viewModel.changeHeadcount(by: -1) }
                    Spacer()
                    Text("\(viewModel.headcount)명").tsFont(.bodyBold).foregroundStyle(Color.tsInk)
                    Spacer()
                    StepButton(icon: "plus") { viewModel.changeHeadcount(by: 1) }
                }
            }
            ComposeField(label: "투입 기간", height: 50) {
                Button { viewModel.isPeriodPickerPresented = true } label: {
                    ComposeValueLabel(value: viewModel.periodText, placeholder: "", icon: .calendar)
                }
                .buttonStyle(.plain)
            }
        }
        ComposeField(label: "요청 사유", height: 88) {
            TextField("목적과 필요한 이유를 알려주세요", text: $viewModel.reason, axis: .vertical)
                .lineLimit(3...6)
                .tsFont(.callout)
                .padding(.vertical, Spacing.md)
        }
    }
}

/// 필요 직군 칩 (iOS · FE · BE · Design · PM)
private struct RoleChipRow: View {
    @Binding var selection: StaffingRole

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("필요 직군")
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            HStack(spacing: Spacing.xs) {
                ForEach(StaffingRole.allCases, id: \.self) { role in
                    let isSelected = selection == role
                    Button { selection = role } label: {
                        Text(role.rawValue)
                            .tsFont(isSelected ? .footnoteBold : .footnoteMedium)
                            .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk2)
                            .padding(.horizontal, Spacing.md + Spacing.xxxs)
                            .frame(height: 35)
                            .background(Capsule().fill(isSelected ? Color.tsPrimary : Color.tsSurface2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

/// 인원 − / + 버튼
private struct StepButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .tsIconSize(.mdLarge, weight: .bold)
                .foregroundStyle(Color.tsInk)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.tsSurface))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon == "plus" ? "인원 늘리기" : "인원 줄이기")
    }
}

#Preview {
    StaffingRequestSheet(viewModel: DIContainer.preview().makeStaffingRequestViewModel(), onFinish: { _ in })
}
