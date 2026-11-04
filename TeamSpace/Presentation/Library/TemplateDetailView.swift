import SwiftUI

/// 06-3 템플릿 상세
struct TemplateDetailView: View {
    @State private var viewModel: TemplateDetailViewModel
    private let onNavigate: (AppRoute) -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TemplateDetailViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Spacing.screen)
                .padding(.top, Spacing.xxl)
                .padding(.bottom, Spacing.xxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let template = viewModel.state.value, template.formKind.composeKind != nil {
                TemplateComposeButton {
                    onNavigate(.templateCompose(kind: template.formKind, title: template.title))
                }
            }
        }
        .background(Color.tsSurface2.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private var navigationBar: some View {
        ZStack {
            Text("템플릿")
                .tsFont(.subheadline)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            HStack {
                CircleIconButton(
                    icon: .templateBack,
                    accessibilityLabel: "뒤로",
                    background: .tsSurface,
                    hasBorder: true,
                    action: { dismiss() }
                )
                Spacer(minLength: 0)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.screen)
        .padding(.top, Spacing.sm)
        .background(Color.tsSurface2)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingSkeletonView(message: "내용을 불러오는 중이에요", count: 2)
        case .loaded(let template):
            TemplateDetailContent(template: template, downloader: viewModel.attachmentDownloader)
        case .empty:
            InfoBanner(message: "템플릿을 찾을 수 없어요.", icon: .file, style: .muted)
        case .forbidden:
            AccessDeniedView(
                onInquire: { onNavigate(.inquiryCompose(.accessRequest)) },
                onBack: { dismiss() }
            )
        case .failed(let error):
            ErrorStateView(message: error.userMessage, title: "내용을 불러오지 못했어요") { Task { await viewModel.load() } }
        }
    }
}

struct TemplateDetailContent: View {
    let template: LibraryTemplate
    var downloader: AttachmentDownloadViewModel? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxl) {
            heading
            VStack(alignment: .leading, spacing: Spacing.sm + Spacing.xxxs) {
                Text("포함된 항목")
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsInk)
                TemplateFieldList(fields: template.fields)
            }
            if let file = template.file {
                AttachmentSection(attachments: [file], downloader: downloader)
            }
            if template.monthlyUsageCount > 0 {
                usageBanner(template.monthlyUsageCount)
            }
        }
    }

    /// 서버에 사용 수가 없으면 숨겨요.
    private func usageBanner(_ count: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            TSIcon.templateUsers.sized(.base)
            Text("이번 달 \(count)명이 이 템플릿을 사용했어요")
                .tsFont(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.tsTemplateAccent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md + Spacing.xxxs)
        .padding(.vertical, Spacing.md + Spacing.hairline)
        .background(Color.tsTemplateBanner, in: RoundedRectangle(cornerRadius: Radius.lg))
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TEMPLATE")
                .tsFont(.micro)
                .tracking(0.2)
                .foregroundStyle(Color.tsTemplateAccent)
                .padding(.horizontal, Spacing.sm + Spacing.hairline)
                .padding(.vertical, Spacing.xxs)
                .background(Color.tsTemplateSoft, in: Capsule())
            Text(template.title)
                .tsFont(.title2)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Text(template.description)
                .tsFont(.footnote)
                .foregroundStyle(Color.tsTemplateSecondary)
                .lineSpacing(Spacing.xxs)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TemplateFieldList: View {
    let fields: [TemplateField]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(fields.enumerated()), id: \.offset) { index, field in
                if index > 0 { TSDivider().foregroundStyle(Color.tsSurface2) }
                HStack(spacing: Spacing.md) {
                    (index == 2 ? TSIcon.templateReason : TSIcon.templateField).sized(.base)
                        .foregroundStyle(Color.tsTemplateAccent)
                        .frame(width: 38, height: 38)
                        .background(Color.tsTemplateSoft, in: RoundedRectangle(cornerRadius: Radius.sm + Spacing.hairline))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.compact) {
                        Text(field.title).tsFont(.calloutBold).foregroundStyle(Color.tsInk)
                        Text(field.subtitle).tsFont(.caption).foregroundStyle(Color.tsInk3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Spacing.lg)
                .accessibilityElement(children: .combine)
            }
        }
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card))
        .tsShadow(.card)
    }
}

struct TemplateComposeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                TSIcon.templateCompose.sized(.action)
                Text("이 템플릿으로 작성하기").tsFont(.bodyBold)
            }
            .foregroundStyle(Color.tsOnPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.tsTemplateButton, in: RoundedRectangle(cornerRadius: Radius.xl + Spacing.xxxs))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screen)
        .padding(.vertical, Spacing.md)
        .background(Color.tsSurface2)
    }
}

#Preview {
    NavigationStack {
        TemplateDetailView(viewModel: DIContainer.preview().makeTemplateDetailViewModel(templateId: "budget-request"), onNavigate: { _ in })
    }
}
