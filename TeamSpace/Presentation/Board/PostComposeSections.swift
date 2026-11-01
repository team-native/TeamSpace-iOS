import PhotosUI
import SwiftUI

/// 10-2 섹션 제목
struct PostComposeLabel: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsInk)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing {
                Text(trailing)
                    .tsFont(.caption2)
                    .foregroundStyle(Color.tsInk3)
            }
        }
    }
}

/// 10-2 작성자 표시 — 실명 · 익명
struct PostAuthorModeSection: View {
    @Bindable var viewModel: PostComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "작성자 표시")
            TSSegmentedControl(
                items: [false, true],
                selection: viewModel.draft.isAnonymous,
                title: { $0 ? "익명" : "실명" },
                onSelect: { viewModel.setAnonymous($0) }
            )
            Text(viewModel.authorNotice)
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
        }
    }
}

/// 10-2 카테고리 — 자유 · 질문 · 정보공유
struct PostCategorySection: View {
    let selection: PostCategory?
    let onSelect: (PostCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "카테고리")
            HStack(spacing: Spacing.xs) {
                ForEach(PostCategory.selectable, id: \.self) { category in
                    FilterChip(title: category.title, isSelected: selection == category) { onSelect(category) }
                }
            }
        }
    }
}

/// 10-2 제목 · 본문 (96 / 5,000)
struct PostTextSection: View {
    @Bindable var viewModel: PostComposeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("제목을 입력해 주세요", text: $viewModel.draft.title)
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
                .padding(.horizontal, Spacing.md + Spacing.xxxs)
                .frame(height: 50)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            ZStack(alignment: .topLeading) {
                if viewModel.draft.body.isEmpty {
                    Text("팀원들과 나누고 싶은 이야기를 써 주세요.")
                        .tsFont(.callout)
                        .foregroundStyle(Color.tsInk3)
                        .padding(.top, Spacing.sm)
                        .padding(.leading, Spacing.xxs)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $viewModel.draft.body)
                    .tsFont(.callout)
                    .foregroundStyle(Color.tsInk)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .accessibilityLabel("본문")
            }
            .padding(Spacing.md)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            HStack {
                Spacer()
                Text(viewModel.bodyCountText)
                    .tsFont(.caption2)
                    .foregroundStyle(viewModel.isBodyOverLimit ? Color.tsNegative : Color.tsInk3)
            }
        }
    }
}

/// 10-2 이미지 첨부 (선택) — JPG · PNG, 최대 5장 · 장당 10MB
struct PostImageSection: View {
    @Bindable var viewModel: PostComposeViewModel
    @State private var pickerItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "이미지 첨부 (선택)", trailing: viewModel.imageCountText)
            if !viewModel.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(viewModel.attachments) { attachment in
                            PostImageThumbnail(attachment: attachment) { viewModel.removeImage(attachment) }
                        }
                    }
                }
            }
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: max(PostDraft.imageLimit - viewModel.attachments.count, 1),
                matching: .images
            ) {
                VStack(spacing: Spacing.xs) {
                    TSIcon.photo.sized(.xl)
                    Text("이미지 첨부하기")
                        .tsFont(.footnoteBold)
                    Text("JPG · PNG, 최대 5장 · 장당 10MB")
                        .tsFont(.caption2)
                        .foregroundStyle(Color.tsInk3)
                }
                .foregroundStyle(Color.tsInk2)
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .strokeBorder(Color.tsLine, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            }
            .disabled(!viewModel.canAddImage)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await load(items) }
            }
        }
    }

    /// HEIC 같은 형식은 JPG 로 바꿔서 넣어요.
    private func load(_ items: [PhotosPickerItem]) async {
        var images: [Data] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            if PostComposeViewModel.isJPEGOrPNG(data) {
                images.append(data)
            } else if let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) {
                images.append(jpeg)
            }
        }
        viewModel.addImages(images)
        pickerItems = []
    }
}

private struct PostImageThumbnail: View {
    let attachment: PostComposeViewModel.Attachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: attachment.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.tsSurface2
                }
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            Button(action: onRemove) {
                TSIcon.close.sized(.xxs, weight: .bold)
                    .foregroundStyle(Color.tsOnInk)
                    .frame(width: 22, height: 22)
                    .background(Color.tsInk.opacity(0.7), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(Spacing.xxs)
            .accessibilityLabel("사진 빼기")
        }
    }
}

/// 10-2 댓글 작성 정책 — 실명 댓글 · 익명 댓글
struct PostCommentPolicySection: View {
    let selection: CommentPolicy
    let onSelect: (CommentPolicy) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            PostComposeLabel(title: "댓글 작성 정책")
            TSSegmentedControl(
                items: [CommentPolicy.realName, .anonymous],
                selection: selection,
                title: { $0 == .realName ? "실명 댓글" : "익명 댓글" },
                onSelect: onSelect
            )
            Text("댓글 작성자는 등록할 때 실명 · 익명을 직접 고를 수 있어요. 여기서 고른 방식이 기본으로 선택돼요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
