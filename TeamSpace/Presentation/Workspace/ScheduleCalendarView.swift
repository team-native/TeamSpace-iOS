import SwiftUI

/// 07-7 일정 — 달력 + 고른 날의 일정. 일정을 누르면 07-9 시트 (Native 일정은 07-8 전체 상세)
struct ScheduleCalendarView: View {
    @State private var viewModel: ScheduleCalendarViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: ScheduleCalendarViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                MonthCalendarCard(viewModel: viewModel)
                Text(viewModel.selectedTitle)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                    .padding(.top, Spacing.xs)
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "일정", onBack: { dismiss() }) {
                Button { onNavigate(.comingSoon(title: "일정 추가")) } label: {
                    TSIcon.plus.sized(.base, weight: .bold)
                        .foregroundStyle(Color.tsOnPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color.tsPrimary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("일정 추가")
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .modifier(ScheduleSheetPresenter(viewModel: viewModel))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 120)
        case .empty, .forbidden:
            InfoBanner(message: "일정을 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.selectedEvents.isEmpty {
                InfoBanner(message: "이 날은 일정이 없어요.", icon: .calendar, style: .muted)
            }
            ForEach(viewModel.selectedEvents) { event in
                Button { open(event) } label: { ScheduleEventRow(event: event) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func open(_ event: ScheduleEvent) {
        if event.opensFullDetail {
            onNavigate(.workspaceScheduleDetail(id: event.id))
        } else {
            viewModel.sheetEvent = event
        }
    }
}

/// 07-9 시트 · 오류 알림
private struct ScheduleSheetPresenter: ViewModifier {
    @Bindable var viewModel: ScheduleCalendarViewModel

    func body(content: Content) -> some View {
        content
            .sheet(item: $viewModel.sheetEvent) { event in
                ScheduleEventSheet(event: event) { response in
                    Task { await viewModel.respond(response) }
                }
                .presentationDetents([.height(440)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Radius.sheet)
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

/// 07-7 일정 한 줄 — 색 막대 · 제목 · 시간 · 장소
struct ScheduleEventRow: View {
    let event: ScheduleEvent

    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.tint)
                .frame(width: 4, height: 42)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(event.title)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                Text(event.listMetaText)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: Spacing.sm)
            TSIcon.chevronRight.sized(.base)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ScheduleCalendarView(viewModel: DIContainer.preview().makeScheduleCalendarViewModel(), onNavigate: { _ in })
    }
}
