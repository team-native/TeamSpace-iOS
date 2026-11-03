import SwiftUI

/// 규칙 문서 등록 · 개정 [Admin] — 제목 · 요약 · 분류 · 시행일 · 조항 · (개정 사유 · 알림)
struct RuleComposeView: View {
    @State private var viewModel: RuleComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: RuleComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ComposeField(label: "제목") {
                    TextField("예) 회의와 의사결정 원칙", text: $viewModel.draft.title)
                        .tsFont(.callout)
                }
                ComposeField(label: "한 줄 요약") {
                    TextField("예) 짧게 논의하고 명확하게 기록하기", text: $viewModel.draft.summary)
                        .tsFont(.callout)
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PostComposeLabel(title: "분류")
                    TSSegmentedControl(
                        items: RuleCategory.selectable,
                        selection: viewModel.draft.category,
                        title: \.title,
                        onSelect: { viewModel.draft.category = $0 }
                    )
                }
                WorkspaceCard {
                    DatePicker("시행일", selection: $viewModel.draft.effectiveDate, displayedComponents: .date)
                        .tsFont(.footnote)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                }
                articlesSection
                if viewModel.isRevision {
                    revisionSection
                }
                InfoBanner(message: viewModel.noticeText, style: .muted)
                Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSubmit)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: viewModel.screenTitle, onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .alert(viewModel.completionTitle, isPresented: $viewModel.didSave) {
            Button("확인") { dismiss() }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            PostComposeLabel(title: "조항", trailing: viewModel.changedCountText)
            ForEach(Array($viewModel.draft.articles.enumerated()), id: \.element.id) { index, $article in
                WorkspaceCard {
                    HStack {
                        Text("제\(index + 1)조")
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsPrimary)
                        if viewModel.isRevision && article.isChanged {
                            Text(article.original == nil ? "새 조항" : "개정")
                                .tsFont(.caption2Bold)
                                .foregroundStyle(Color.tsNegative)
                        }
                        Spacer()
                        if viewModel.draft.articles.count > 1 {
                            CircleIconButton(icon: .close, accessibilityLabel: "제\(index + 1)조 지우기", size: 28) {
                                viewModel.removeArticle(article)
                            }
                        }
                    }
                    TextField("조항 제목 (예: 목적)", text: $article.title)
                        .tsFont(.calloutBold)
                    TextEditor(text: $article.body)
                        .tsFont(.callout)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 90)
                        .padding(Spacing.sm)
                        .background(Color.tsBackground, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                        .accessibilityLabel("제\(index + 1)조 내용")
                }
            }
            Button("조항 추가") { viewModel.addArticle() }
                .buttonStyle(.tsSecondary)
        }
    }

    private var revisionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ComposeField(label: "개정 사유") {
                TextField("예) 제2조 검토 기한 3주 → 2주", text: $viewModel.draft.note)
                    .tsFont(.callout)
            }
            WorkspaceCard {
                Toggle(isOn: $viewModel.draft.notifies) {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("구성원에게 알림 보내기")
                            .tsFont(.footnoteBold)
                        Text("‘문서가 개정됐어요’ 알림이 가요")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .tint(Color.tsPrimary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RuleComposeView(viewModel: DIContainer.preview().makeRuleComposeViewModel(user: AuthUser(id: 1, name: "관리자", roles: [.admin])))
    }
}
