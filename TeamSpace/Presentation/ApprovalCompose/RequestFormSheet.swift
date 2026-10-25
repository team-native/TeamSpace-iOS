import SwiftUI
import UniformTypeIdentifiers

/// 05-11 기타 내부 문서 · 05-12 프로젝트 관련 요청서 · 05-13 운영 관련 요청서 (시트)
struct RequestFormSheet: View {
    @State private var viewModel: RequestFormViewModel
    private let onFinish: (SubmittedDocument?) -> Void

    init(viewModel: RequestFormViewModel, onFinish: @escaping (SubmittedDocument?) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onFinish = onFinish
    }

    var body: some View {
        ScrollView {
            form
                .padding(.horizontal, Spacing.screen)
                .padding(.top, Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background(Color.tsSurface)
        .sheet(isPresented: $viewModel.isDatePickerPresented) {
            UseDatePickerSheet(date: $viewModel.desiredDate)
                .presentationDetents([.height(480)])
        }
        .fileImporter(isPresented: $viewModel.isFileImporterPresented, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result { viewModel.addAttachment(named: url.lastPathComponent) }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: errorBinding) {
            Button("확인", role: .cancel) {}
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            ComposeSheetHeader(title: viewModel.kind.title, subtitle: viewModel.kind.subtitle, onClose: { onFinish(nil) })
            if viewModel.kind == .etc {
                EtcDocumentFields(viewModel: viewModel)
            } else {
                RequestFormFields(viewModel: viewModel)
            }
            AttachmentPicker(names: viewModel.attachmentNames, onAdd: { viewModel.isFileImporterPresented = true }) {
                viewModel.removeAttachment(named: $0)
            }
            ApprovalLinePreview(approvers: viewModel.kind.approvalLine)
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
            Button(viewModel.kind == .etc ? "결재 올리기" : "결재 요청 제출") {
                Task { if let result = await viewModel.submit() { onFinish(result) } }
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

/// 05-12 · 05-13 항목
private struct RequestFormFields: View {
    @Bindable var viewModel: RequestFormViewModel

    private var isProject: Bool { viewModel.kind == .project }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            ComposeField(label: isProject ? "프로젝트" : "담당 부서") {
                Menu {
                    Picker("", selection: $viewModel.target) {
                        ForEach(viewModel.targets, id: \.self) { Text($0).tag($0) }
                    }
                } label: {
                    ComposeValueLabel(value: viewModel.target, placeholder: "선택해 주세요")
                }
            }
            ComposeField(label: isProject ? "희망 반영일" : "희망 처리일") {
                Button { viewModel.isDatePickerPresented = true } label: {
                    ComposeValueLabel(value: TSFormat.fullDate(viewModel.desiredDate), placeholder: "", icon: .calendar)
                }
                .buttonStyle(.plain)
            }
        }
        CategoryChips(
            title: isProject ? "요청 종류" : "요청 분류",
            items: viewModel.kind.categories,
            selection: $viewModel.category
        )
        HStack(alignment: .top, spacing: Spacing.sm + Spacing.xxxs) {
            if isProject {
                ComposeField(label: "필요 인원") {
                    TextField("예) QA 1명", text: $viewModel.quantity).tsFont(.callout)
                }
                ComposeField(label: "기간") {
                    TextField("예) 10.23 – 10.31", text: $viewModel.period).tsFont(.callout)
                }
            } else {
                ComposeField(label: "예상 금액") {
                    HStack(spacing: Spacing.xxs) {
                        TextField("0", text: Binding(get: { viewModel.formattedAmount }, set: { viewModel.updateAmount($0) }))
                            .keyboardType(.numberPad)
                            .tsFont(.callout)
                        Text("원").tsFont(.callout).foregroundStyle(Color.tsInk3)
                    }
                }
                ComposeField(label: "수량") {
                    TextField("예) 2개", text: $viewModel.quantity).tsFont(.callout)
                }
            }
        }
        ComposeField(label: isProject ? "요청 상세 · 사유" : "내용 · 사유", height: 76) {
            TextField("목적과 필요한 이유를 알려주세요", text: $viewModel.body, axis: .vertical)
                .lineLimit(2...6)
                .tsFont(.callout)
                .padding(.vertical, Spacing.md)
        }
    }
}

/// 05-11 제목 · 본문
private struct EtcDocumentFields: View {
    @Bindable var viewModel: RequestFormViewModel

    var body: some View {
        ComposeField(label: "제목") {
            TextField("예) 10월 외주 회고 정리 공유 건", text: $viewModel.title).tsFont(.callout)
        }
        ComposeField(label: "본문", height: 150) {
            TextField("공유하거나 보고할 내용을 적어 주세요", text: $viewModel.body, axis: .vertical)
                .lineLimit(5...12)
                .tsFont(.callout)
                .padding(.vertical, Spacing.md)
                .frame(minHeight: 150, alignment: .top)
        }
    }
}

/// 요청 종류 · 분류 칩 (한 개 선택)
private struct CategoryChips: View {
    let title: String
    let items: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .tsFont(.captionBold)
                .foregroundStyle(Color.tsInk2)
            HStack(spacing: Spacing.xs) {
                ForEach(items, id: \.self) { item in
                    let isSelected = selection == item
                    Button { selection = item } label: {
                        Text(item)
                            .tsFont(isSelected ? .footnoteBold : .footnoteMedium)
                            .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk2)
                            .padding(.horizontal, Spacing.md + Spacing.xxxs)
                            .frame(height: 33)
                            .background(Capsule().fill(isSelected ? Color.tsPrimary : Color.tsSurface))
                            .overlay(Capsule().stroke(isSelected ? Color.clear : Color.tsLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

#Preview("05-12") {
    RequestFormSheet(viewModel: DIContainer.preview().makeRequestFormViewModel(kind: .project), onFinish: { _ in })
}

#Preview("05-11") {
    RequestFormSheet(viewModel: DIContainer.preview().makeRequestFormViewModel(kind: .etc), onFinish: { _ in })
}
