import SwiftUI

/// Figma `sparkline` — 값의 흐름을 선 + 아래 그라디언트로 그립니다.
struct SparklineView: View {
    let values: [Int]
    var tint: Color = .tsPrimary

    var body: some View {
        GeometryReader { proxy in
            let points = Self.points(values, in: proxy.size)
            ZStack {
                areaPath(points, height: proxy.size.height)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.18), tint.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                linePath(points)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }

    private func linePath(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
        }
    }

    private func areaPath(_ points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            points.forEach { path.addLine(to: $0) }
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.closeSubpath()
        }
    }

    /// 최솟값은 아래 · 최댓값은 위 (위아래 여백 8pt)
    static func points(_ values: [Int], in size: CGSize) -> [CGPoint] {
        guard values.count > 1, let minValue = values.min(), let maxValue = values.max() else { return [] }
        let inset: CGFloat = 8
        let range = CGFloat(max(maxValue - minValue, 1))
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            let ratio = CGFloat(value - minValue) / range
            return CGPoint(x: CGFloat(index) * stepX, y: inset + (1 - ratio) * (size.height - inset * 2))
        }
    }
}

#Preview {
    SparklineView(values: [2, 4, 3, 6, 5, 8, 7, 9])
        .frame(height: 72)
        .padding()
}
