import SwiftUI

/// 11-1 내 문의 (Figma 수정본) — 상태 칩 · 처리 흐름 · 문의 카드
struct MyInquiriesView: View {
    @State private var viewModel: MyInquiriesViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyInquiriesViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("보낸 의견, 여기서 확인해요.")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                    Text("내가 제출한 문의와 건의만 볼 수 있어요.")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
                .padding(.top, Spacing.sm)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(InquiryFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.title, isSelected: viewModel.filter == filter) { viewModel.filter = filter }
                        }
                    }
                    .padding(1)
                }
                InquiryFlowCard()
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "내 문의", onBack: { dismiss() }) {
                Button("새 문의") { onNavigate(.inquiryCompose(.blank)) }
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsPrimary)
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.sm)
            .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView()
        case .empty, .forbidden:
            InfoBanner(message: "문의를 볼 수 있는 권한이 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            ErrorStateView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded:
            if viewModel.inquiries.isEmpty {
                InfoBanner(message: viewModel.emptyMessage, style: .muted)
            }
            ForEach(viewModel.inquiries) { inquiry in
                InquiryCard(inquiry: inquiry) { onNavigate(.inquiryDetail(id: inquiry.id)) }
            }
        }
    }
}

/// 11-1 처리 흐름 — 접수 → 검토 중 → 답변 완료 / 반려
private struct InquiryFlowCard: View {
    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "처리 흐름")
            HStack(spacing: Spacing.xs) {
                ForEach(Array(InquiryStatus.flow.enumerated()), id: \.offset) { index, status in
                    if index > 0 {
                        Text(index == InquiryStatus.flow.count - 1 ? "/" : "→")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    StatusBadge(status: status, size: .small)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// 11-1 문의 카드 — 대상 · 날짜 · 익명 · 상태 · 제목 · 내용 · (답변)
private struct InquiryCard: View {
    let inquiry: InquirySummary
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            WorkspaceCard {
                HStack {
                    Text(inquiry.metaText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                    Spacer(minLength: Spacing.sm)
                    StatusBadge(status: inquiry.status, size: .small)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(inquiry.title)
                        .tsFont(.bodyBold)
                        .foregroundStyle(Color.tsInk)
                        .multilineTextAlignment(.leading)
                    Text(inquiry.body)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                        .lineLimit(1)
                }
                if let replyTitle = inquiry.replyTitle, let reply = inquiry.reply {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(replyTitle)
                            .tsFont(.caption2Bold)
                            .foregroundStyle(inquiry.status == .rejected ? Color.tsNegative : Color.tsPrimary)
                        Text(reply.body)
                            .tsFont(.caption)
                            .foregroundStyle(Color.tsInk2)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MyInquiriesView(viewModel: DIContainer.preview().makeMyInquiriesViewModel(), onNavigate: { _ in })
    }
}
