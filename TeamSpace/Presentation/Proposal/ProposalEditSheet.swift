import SwiftUI

/// 12-2b 내 제안 고치기 — 대상 부서 · 제목 · 내용 (접수 상태일 때만, 익명 여부는 그대로)
struct ProposalEditSheet: View {
    @Bindable var viewModel: ProposalDetailViewModel

    private var draft: Binding<ProposalDraft> {
        Binding(
            get: { viewModel.editDraft ?? ProposalDraft() },
            set: { viewModel.editDraft = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Button("취소") { viewModel.editDraft = nil }
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk2)
                Spacer()
                Text("제안 수정")
                    .tsFont(.headline)
                    .foregroundStyle(Color.tsInk)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("저장") { Task { await viewModel.saveEdit() } }
                    .tsFont(.calloutBold)
                    .foregroundStyle(viewModel.canSaveEdit ? Color.tsPrimary : Color.tsInk3)
                    .disabled(!viewModel.canSaveEdit)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        PostComposeLabel(title: "대상 부서")
                        FlowLayout(spacing: Spacing.xs) {
                            ForEach(ProposalDraft.departments, id: \.self) { department in
                                FilterChip(title: department, isSelected: draft.wrappedValue.department == department) {
                                    draft.wrappedValue.department = department
                                }
                            }
                        }
                    }
                    TextField("어떤 점을 바꾸면 좋을까요?", text: draft.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .padding(.horizontal, Spacing.md + Spacing.xxxs)
                        .frame(minHeight: 50)
                        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    TextEditor(text: draft.body)
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 180)
                        .padding(Spacing.md)
                        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                        .accessibilityLabel("제안 내용")
                    HStack {
                        Text(draft.wrappedValue.isAnonymous ? "익명으로 올린 제안이에요." : "실명으로 올린 제안이에요.")
                        Spacer()
                        Text("\(TSFormat.number(draft.wrappedValue.body.count)) / \(TSFormat.number(ProposalDraft.bodyLimit))")
                            .foregroundStyle(draft.wrappedValue.body.count > ProposalDraft.bodyLimit ? Color.tsNegative : Color.tsInk3)
                    }
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(Spacing.screen)
        .background(Color.tsBackground.ignoresSafeArea())
        .presentationDetents([.large])
        .interactiveDismissDisabled(viewModel.isSavingEdit)
    }
}
