import SwiftUI

/// 10-6 공지 상세 — 분류 · 필독 · 작성자 · 본문 · 연결 문서 · 확인했어요
struct NoticeDetailView: View {
    @State private var viewModel: NoticeDetailViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: NoticeDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
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
            TSNavigationBar(title: "공지", onBack: { dismiss() }) {
                if viewModel.canEdit, let id = viewModel.detail?.notice.id {
                    CircleIconButton(icon: .pencil, accessibilityLabel: "공지 수정", background: .tsSurface, hasBorder: true) {
                        onNavigate(.noticeEdit(id: id))
                    }
                }
            }
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let detail = viewModel.detail {
                Button(detail.acknowledgeTitle) { Task { await viewModel.acknowledge() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(viewModel.isAcknowledged || viewModel.isAcknowledging)
                    .padding(.horizontal, Spacing.screen)
                    .padding(.vertical, Spacing.md)
                    .background(Color.tsBackground)
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didAcknowledge) { _, done in
            if done { dismiss() }
        }
        .alert(viewModel.errorMessage ?? "", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .empty, .forbidden:
            AccessDeniedView(
                onInquire: { onNavigate(.inquiryCompose(.accessRequest)) },
                onBack: { dismiss() }
            )
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
        case .loaded(let detail):
            NoticeDetailHeader(detail: detail)
            if let document = detail.linkedDocument {
                NoticeLinkedDocumentCard(document: document) { onNavigate(document.route) }
            }
        }
    }
}

/// 10-6 위 — 분류 · 필독 · 제목 · 작성자 · 날짜 · 조회 · 본문
private struct NoticeDetailHeader: View {
    let detail: NoticeDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(status: detail.notice.category, size: .small)
                if detail.notice.isImportant {
                    StatusBadge(title: "필독", tone: .negative, size: .small)
                }
            }
            Text(detail.notice.title)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.sm) {
                AvatarView(size: 36)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(detail.authorText)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    Text(detail.metaText)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
            }
            .accessibilityElement(children: .combine)
            TSDivider()
            Text(detail.body)
                .tsFont(.body)
                .foregroundStyle(Color.tsInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(.top, Spacing.sm)
    }
}

/// 10-6 연결 문서 — "외주 수금 및 풀 배분 기준 · 문서함 · FINANCE"
private struct NoticeLinkedDocumentCard: View {
    let document: NoticeLinkedDocument
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: Spacing.md) {
                IconTile(icon: .file)
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(document.title)
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    Text(document.caption)
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                Spacer(minLength: Spacing.sm)
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(Spacing.lg)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        NoticeDetailView(viewModel: DIContainer.preview().makeNoticeDetailViewModel(noticeId: 41), onNavigate: { _ in })
    }
}
