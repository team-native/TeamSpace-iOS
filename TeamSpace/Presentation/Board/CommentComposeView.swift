import SwiftUI

/// 10-4 댓글 작성 · 실명 / 익명 선택 — 등록 전에 다른 구성원에게 보이는 모습을 미리 보여줘요.
struct CommentComposeView: View {
    @State private var viewModel: CommentComposeViewModel

    @Environment(\.dismiss) private var dismiss

    init(viewModel: CommentComposeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                content
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "댓글 작성", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.post != nil {
                Button(viewModel.submitTitle) { Task { await viewModel.submit() } }
                    .buttonStyle(.tsPrimaryLarge)
                    .disabled(!viewModel.canSubmit)
                    .padding(.horizontal, Spacing.screen)
                    .padding(.vertical, Spacing.md)
                    .background(Color.tsBackground)
            }
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onChange(of: viewModel.didSubmit) { _, didSubmit in
            if didSubmit { dismiss() }
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
            ProgressView().frame(maxWidth: .infinity, minHeight: 240)
        case .empty, .forbidden:
            InfoBanner(message: "이 게시글에는 댓글을 남길 수 없어요.", icon: .lock, style: .muted)
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let detail):
            WorkspacePageTitle(eyebrow: "다른 팀원들에게 자유롭게 생각을 들려주세요", title: detail.post.title)
            CommentOriginCard(originText: viewModel.originText, excerpt: detail.post.excerpt)
            CommentAuthorModeSection(viewModel: viewModel)
            CommentPreviewCard(viewModel: viewModel)
            CommentBodySection(viewModel: viewModel)
            InfoBanner(
                message: "댓글은 이 게시글을 볼 수 있는 구성원에게 공개돼요. 익명 선택 시 공개 화면에 실명을 표시하지 않아요. "
                    + "본인의 익명 댓글은 내 공간에서 확인할 수 있어요.",
                style: .muted
            )
            InfoBanner(message: "글쓴이가 댓글 작성자의 실명·익명 선택을 대신 정하지 않아요. 등록 전 표시 미리보기를 확인해 주세요.")
        }
    }
}

/// 10-4 원글 요약
private struct CommentOriginCard: View {
    let originText: String
    let excerpt: String

    var body: some View {
        WorkspaceCard {
            Text(originText)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            Text(excerpt)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsInk2)
                .lineLimit(3)
        }
    }
}

/// 10-4 댓글의 이름은 내가 선택해요 — 실명 · 옥물결 / 익명
private struct CommentAuthorModeSection: View {
    @Bindable var viewModel: CommentComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "댓글의 이름은 내가 선택해요")
            Text("원글이 실명이거나 익명이어도, 댓글 작성자는 자신의 표시 방식을 따로 선택할 수 있어요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
            TSSegmentedControl(
                items: [false, true],
                selection: viewModel.draft.isAnonymous,
                title: { $0 ? "익명" : viewModel.realNameTitle },
                onSelect: { viewModel.draft.isAnonymous = $0 }
            )
        }
    }
}

/// 10-4 다른 구성원에게 보이는 모습
private struct CommentPreviewCard: View {
    let viewModel: CommentComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "다른 구성원에게 보이는 모습")
            WorkspaceCard {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    PostAuthorAvatar(isAnonymous: viewModel.draft.isAnonymous)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(viewModel.previewName)
                            .tsFont(.captionBold)
                            .foregroundStyle(Color.tsInk)
                        Text(viewModel.previewBody)
                            .tsFont(.footnote)
                            .foregroundStyle(Color.tsInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.previewMeta)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// 10-4 댓글 내용 — 최대 1,000자
private struct CommentBodySection: View {
    @Bindable var viewModel: CommentComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "댓글 내용", trailing: "최대 1,000자")
            TextEditor(text: $viewModel.draft.body)
                .tsFont(.callout)
                .foregroundStyle(Color.tsInk)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(Spacing.md)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .accessibilityLabel("댓글 내용")
            HStack {
                Spacer()
                Text(viewModel.countText)
                    .tsFont(.caption2)
                    .foregroundStyle(viewModel.draft.body.count > CommentDraft.bodyLimit ? Color.tsNegative : Color.tsInk3)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommentComposeView(viewModel: DIContainer.preview().makeCommentComposeViewModel(postId: 41, userName: "옥물결"))
    }
}
