import SwiftUI

/// 일정 추가 [Admin] — 제목 · 구분 · 날짜 · 시각 · 장소 · 안건 · 참석 확인
struct ScheduleComposeView: View {
    @State private var viewModel: ScheduleComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ScheduleComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ComposeField(label: "제목") {
                    TextField("일정 제목", text: $viewModel.draft.title)
                        .tsFont(.callout)
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PostComposeLabel(title: "구분")
                    TSSegmentedControl(
                        items: ScheduleScope.allCases,
                        selection: viewModel.draft.scope,
                        title: \.rawValue,
                        onSelect: { viewModel.draft.scope = $0 }
                    )
                }
                timeCard
                ComposeField(label: "장소") {
                    TextField("예) 3층 라운지 · 온라인 Discord", text: $viewModel.draft.place)
                        .tsFont(.callout)
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PostComposeLabel(title: "안건")
                    TextEditor(text: $viewModel.draft.agenda)
                        .tsFont(.callout)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(Spacing.md)
                        .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                        .accessibilityLabel("안건")
                }
                WorkspaceCard {
                    Toggle(isOn: $viewModel.draft.asksRSVP) {
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text("참석 확인 받기")
                                .tsFont(.footnoteBold)
                            Text("구성원이 참석 · 불참을 고를 수 있어요")
                                .tsFont(.caption2)
                                .foregroundStyle(Color.tsInk3)
                        }
                    }
                    .tint(Color.tsPrimary)
                }
                InfoBanner(message: viewModel.noticeText, style: .muted)
                Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSubmit || viewModel.timeHint != nil)
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
        .alert(viewModel.completionTitle, isPresented: $viewModel.didCreate) {
            Button("확인") { dismiss() }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "날짜 · 시각")
            WorkspaceCard {
                DatePicker("날짜", selection: $viewModel.draft.date, displayedComponents: .date)
                    .tsFont(.footnote)
                TSDivider()
                DatePicker("시작", selection: $viewModel.draft.startsAt, displayedComponents: .hourAndMinute)
                    .tsFont(.footnote)
                TSDivider()
                DatePicker("끝", selection: $viewModel.draft.endsAt, displayedComponents: .hourAndMinute)
                    .tsFont(.footnote)
            }
            .environment(\.locale, Locale(identifier: "ko_KR"))
            if let hint = viewModel.timeHint {
                Text(hint)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsNegative)
            }
        }
    }
}
