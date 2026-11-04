import SwiftUI
import UIKit

/// 10-3 게시글 첨부 사진 — 받아 온 사진을 본문 아래에 세로로 보여주고, 누르면 크게 열어요.
struct PostImageGallery: View {
    let images: [FileAttachment]
    var downloader: AttachmentDownloadViewModel?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(images) { file in
                PostImageTile(file: file, downloader: downloader)
            }
        }
        .modifier(AttachmentPreviewModifier(downloader: downloader))
    }
}

private struct PostImageTile: View {
    let file: FileAttachment
    let downloader: AttachmentDownloadViewModel?

    private var image: UIImage? {
        downloader?.localURLs[file.id].flatMap { UIImage(contentsOfFile: $0.path) }
    }

    private var isFailed: Bool {
        downloader == nil || downloader?.failedIds.contains(file.id) == true
    }

    var body: some View {
        Button {
            guard let downloader else { return }
            Task { await downloader.open(file) }
        } label: {
            content
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(image == nil)
        .accessibilityLabel("첨부 사진 \(file.name)")
        .accessibilityHint(image == nil ? "" : "크게 봐요")
        .task(id: file.id) { await downloader?.prefetch(file) }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ZStack {
                Color.tsSurface2
                if isFailed {
                    VStack(spacing: Spacing.xs) {
                        TSIcon.photo.sized(.lg)
                        Text("사진을 불러오지 못했어요")
                            .tsFont(.caption2)
                    }
                    .foregroundStyle(Color.tsInk3)
                } else {
                    ProgressView()
                }
            }
            .frame(height: 200)
        }
    }
}
