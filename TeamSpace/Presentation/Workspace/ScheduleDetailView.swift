import SwiftUI

/// 07-8 전체 일정 상세 (Native 일정)
struct ScheduleDetailView: View {
    @State private var viewModel: ScheduleDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ScheduleDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "Native 일정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(ScheduleDetailSheets(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 일정을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            ScheduleDetailHeader(detail: detail)
            ScheduleMeetingInfoCard(detail: detail)
            if !detail.agenda.isEmpty {
                ScheduleAgendaCard(agenda: detail.agenda, note: detail.agendaNote)
            }
            ScheduleResponseCard(
                selected: detail.event.myResponse,
                savedText: viewModel.savedResponseText,
                onSelect: { response in Task { await viewModel.respond(response) } }
            )
            if let document = detail.relatedDocument {
                ScheduleDocumentCard(document: document) { onNavigate(.comingSoon(title: document.title)) }
            }
            ScheduleHistoryCard(history: detail.history, note: detail.historyNote)
            ScheduleReminderCard(reminders: detail.reminders, onEdit: { viewModel.openReminderEditor() })
            Text("이 화면은 전체 정기 활동이에요. 참여 프로젝트의 개별 일정 변경은 개인 업무 알림에서 확인해요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}

/// 리마인더 변경 시트 · 오류 알림
private struct ScheduleDetailSheets: ViewModifier {
    @Bindable var viewModel: ScheduleDetailViewModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isReminderEditorPresented) {
                ReminderEditorSheet(viewModel: viewModel)
                    .presentationDetents([.height(360)])
                    .presentationDragIndicator(.visible)
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

#Preview {
    NavigationStack {
        ScheduleDetailView(viewModel: DIContainer.preview().makeScheduleDetailViewModel(scheduleId: 2), onNavigate: { _ in })
    }
}
