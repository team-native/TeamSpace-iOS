import SwiftUI
import UniformTypeIdentifiers

/// 05-5 비용 승인 요청 (시트)
struct ExpenseRequestSheet: View {
    @State private var viewModel: ExpenseRequestViewModel
    /// 제출하면 결과, 임시 저장 · 닫기면 nil
    private let onFinish: (SubmittedDocument?) -> Void

    init(viewModel: ExpenseRequestViewModel, onFinish: @escaping (SubmittedDocument?) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                ComposeSheetHeader(
                    title: "비용 승인 요청",
                    subtitle: "제출하면 결재선 순서대로 검토가 시작돼요.",
                    onClose: { onFinish(nil) }
                )
                ExpenseFormFields(viewModel: viewModel)
                AttachmentPicker(names: viewModel.attachmentNames, onAdd: { viewModel.isFileImporterPresented = true }) {
                    viewModel.removeAttachment(named: $0)
                }
                ApprovalLinePreview(approvers: ApprovalLinePreview.defaultLine)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background(Color.tsSurface)
        .sheet(isPresented: $viewModel.isDatePickerPresented) {
            UseDatePickerSheet(date: $viewModel.useDate)
                .presentationDetents([.height(480)])
        }
        .fileImporter(isPresented: $viewModel.isFileImporterPresented, allowedContentTypes: [.pdf, .image]) { result in
            if case .success(let url) = result {
                viewModel.addAttachment(named: url.lastPathComponent)
            }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    private var actions: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                Task { if await viewModel.saveDraft() { onFinish(nil) } }
            } label: {
                Text("임시 저장")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk2)
                    .frame(width: 95, height: 50)
                    .background(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).fill(Color.tsSurface2))
            }
            .buttonStyle(.plain)
            Button("결재 요청 제출") {
                Task {
                    if let result = await viewModel.submit() { onFinish(result) }
                }
            }
            .buttonStyle(.tsPrimary)
            .disabled(!viewModel.canSubmit)
        }
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.md)
        .background(Color.tsSurface)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

/// 비용 유형 · 프로젝트 · 요청 내용 · 금액 · 사용 예정일 · 요청 사유
private struct ExpenseFormFields: View {
    @Bindable var viewModel: ExpenseRequestViewModel

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            ComposeField(label: "비용 유형") {
                Menu {
                    Picker("비용 유형", selection: $viewModel.expenseType) {
                        ForEach(ExpenseType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(Optional(type))
                        }
                    }
                } label: {
                    ComposeValueLabel(value: viewModel.expenseType?.rawValue, placeholder: "선택해 주세요")
                }
            }
            ComposeField(label: "프로젝트 · 사용처") {
                TextField("예) Book-on", text: $viewModel.project)
                    .tsFont(.callout)
            }
        }
        ComposeField(label: "요청 내용") {
            TextField("필요한 물품이나 비용을 적어주세요", text: $viewModel.content)
                .tsFont(.callout)
        }
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            ComposeField(label: "요청 금액") {
                HStack(spacing: Spacing.xxs) {
                    TextField("0", text: Binding(get: { viewModel.formattedAmount }, set: { viewModel.updateAmount($0) }))
                        .keyboardType(.numberPad)
                        .tsFont(.callout)
                    Text("원")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            ComposeField(label: "사용 예정일") {
                Button { viewModel.isDatePickerPresented = true } label: {
                    ComposeValueLabel(value: TSFormat.fullDate(viewModel.useDate), placeholder: "", icon: .calendar)
                }
                .buttonStyle(.plain)
            }
        }
        ComposeField(label: "요청 사유", height: 76) {
            TextField("목적과 필요한 이유를 알려주세요", text: $viewModel.reason, axis: .vertical)
                .lineLimit(2...5)
                .tsFont(.callout)
                .padding(.vertical, Spacing.md)
        }
    }
}

/// 첨부 (견적서 · 영수증)
struct AttachmentPicker: View {
    let names: [String]
    let onAdd: () -> Void
    let onRemove: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("첨부 (견적서 · 영수증)")
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            ForEach(names, id: \.self) { name in
                HStack(spacing: Spacing.sm) {
                    TSIcon.file.sized(.base).foregroundStyle(Color.tsPrimary)
                    Text(name).tsFont(.footnote).foregroundStyle(Color.tsInk).lineLimit(1)
                    Spacer()
                    Button { onRemove(name) } label: { TSIcon.close.sized(.sm, weight: .bold) }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.tsInk3)
                        .accessibilityLabel("\(name) 삭제")
                }
            }
            Button(action: onAdd) {
                HStack(spacing: Spacing.xs) {
                    TSIcon.plus.sized(.base, weight: .semibold)
                    Text("파일 추가").tsFont(.calloutBold)
                }
                .foregroundStyle(Color.tsPrimary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(Color.tsPrimary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ExpenseRequestSheet(viewModel: DIContainer.preview().makeExpenseRequestViewModel(), onFinish: { _ in })
}
