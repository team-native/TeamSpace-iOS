import UIKit

/// 07-16 고른 사진 · 스티커를 올리기 좋은 크기로 줄여요.
/// 긴 변 512pt 로 줄이고, 투명한 부분이 있는 스티커는 PNG, 사진은 JPEG 로 바꿔요.
enum ProfilePhotoEncoder {
    static let maxDimension: CGFloat = 512

    static func encode(_ data: Data) -> (data: Data, mimeType: String)? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = resize(image)
        if hasAlpha(resized), let png = resized.pngData() {
            return (png, "image/png")
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        return (jpeg, "image/jpeg")
    }

    private static func resize(_ image: UIImage) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = !hasAlpha(image)
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func hasAlpha(_ image: UIImage) -> Bool {
        switch image.cgImage?.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: return true
        default: return false
        }
    }
}
