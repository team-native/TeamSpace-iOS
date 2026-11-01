import SwiftUI
import UniformTypeIdentifiers

/// 10-7 공지 대상 · 중요 공지 · 상단 고정
struct NoticeAudienceSection: View {
    @Bindable var viewModel: NoticeComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "공지 대상")
            TSSegmentedControl(
                items: NoticeAudience.allCases,
                selection: viewModel.draft.audience,
                title: \.title,
                onSelect: { viewModel.draft.audience = $0 }
            )
            Text(viewModel.draft.audience.note)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
            HStack(spacing: Spacing.xs) {
                NoticeCheckChip(title: "중요 공지", isOn: $viewModel.draft.isImportant)
                NoticeCheckChip(title: "상단 고정", isOn: $viewModel.draft.isPinned)
            }
        }
    }
}

/// "✓ 중요 공지" 켜고 끄는 칩
private struct NoticeCheckChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: Spacing.xxs) {
                if isOn {
                    TSIcon.check.sized(.xs, weight: .bold)
                }
                Text(title)
                    .tsFont(.captionBold)
            }
            .foregroundStyle(isOn ? Color.tsPrimary : Color.tsInk2)
            .padding(.horizontal, Spacing.md)
            .frame(height: 32)
            .background(isOn ? Color.tsPrimarySoft : Color.tsSurface, in: Capsule())
            .overlay(Capsule().stroke(isOn ? Color.clear : Color.tsLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// 10-7 제목 · 본문
struct NoticeTextSection: View {
    @Bindable var viewModel: NoticeComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            ComposeField(label: "제목") {
                TextField("공지 제목", text: $viewModel.draft.title)
                    .tsFont(.callout)
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                PostComposeLabel(title: "본문")
                TextEditor(text: $viewModel.draft.body)
                    .tsFont(.callout)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(Spacing.md)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    .accessibilityLabel("본문")
            }
        }
    }
}

/// 10-7 첨부 — 파일 이름 · 크기 · 업로드 완료
struct NoticeAttachmentSection: View {
    @Bindable var viewModel: NoticeComposeViewModel
    @State private var isImporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "첨부")
            ForEach(viewModel.draft.attachments) { attachment in
                HStack(spacing: Spacing.md) {
                    IconTile(icon: .file, iconSize: .lg, tileSize: 36)
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(attachment.fileName)
                            .tsFont(.footnoteBold)
                            .foregroundStyle(Color.tsInk)
                            .lineLimit(1)
                        Text(attachment.sizeText)
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                    Spacer(minLength: Spacing.sm)
                    CircleIconButton(icon: .close, accessibilityLabel: "\(attachment.fileName) 빼기", size: 28) {
                        viewModel.removeAttachment(attachment)
                    }
                }
                .padding(Spacing.md)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
            Button("첨부 추가") { isImporting = true }
                .buttonStyle(.tsSecondary)
                .disabled(!viewModel.canAddAttachment)
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf, .image], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                let isScoped = url.startAccessingSecurityScopedResource()
                defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else { continue }
                viewModel.addAttachment(fileName: url.lastPathComponent, data: data)
            }
        }
    }
}

/// 10-7 게시 시점 · 예약 일시 · 푸시
struct NoticeTimingSection: View {
    @Bindable var viewModel: NoticeComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "게시 시점")
            TSSegmentedControl(
                items: [NoticePublishTiming.now, .scheduled],
                selection: viewModel.draft.timing,
                title: { $0 == .now ? "지금 게시" : "예약 게시" },
                onSelect: { viewModel.draft.timing = $0 }
            )
            WorkspaceCard {
                if viewModel.draft.timing == .scheduled {
                    DatePicker("예약 일시", selection: $viewModel.draft.scheduledAt, in: Date()...)
                        .tsFont(.footnote)
                    TSDivider()
                }
                Toggle(isOn: $viewModel.draft.sendsPush) {
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text("푸시")
                            .tsFont(.footnoteBold)
                        Text("게시 시 함께 발송")
                            .tsFont(.caption2)
                            .foregroundStyle(Color.tsInk3)
                    }
                }
                .tint(Color.tsPrimary)
            }
            .environment(\.locale, Locale(identifier: "ko_KR"))
        }
    }
}

/// 10-7 푸시 미리보기 — 민감 내용은 숨긴 문구
struct NoticePushPreview: View {
    let audience: NoticeAudience
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "푸시 미리보기")
            HStack(alignment: .top, spacing: Spacing.md) {
                BrandLogoTile()
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("전체 공지 · \(audience.title)")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                    Text("새 전체 공지가 등록됐어요")
                        .tsFont(.footnoteBold)
                        .foregroundStyle(Color.tsInk)
                    Text("\(audience.title) 앱에서 공지를 확인해 주세요.")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk2)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .accessibilityElement(children: .combine)
            Text(isEnabled ? "민감 내용 숨기기 기준 미리보기 · 알림을 누르면 공지 상세로 이동해요." : "푸시를 끄면 알림 없이 게시돼요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

private struct BrandLogoTile: View {
    var body: some View {
        IconTile(icon: .bell, iconSize: .base, tileSize: 32, tint: .tsOnPrimary, background: .tsPrimary)
    }
}

/// 10-7 게시 전 확인
struct NoticeChecklistCard: View {
    let lines: [String]

    var body: some View {
        WorkspaceCard {
            WorkspaceCardTitle(title: "게시 전 확인")
            ForEach(lines, id: \.self) { line in
                HStack(spacing: Spacing.xs) {
                    TSIcon.check.sized(.xs, weight: .bold)
                        .foregroundStyle(Color.tsPositive)
                    Text(line)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk)
                }
            }
        }
    }
}
