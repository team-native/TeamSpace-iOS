import SwiftUI

/// 칩처럼 가로로 늘어놓다가 줄이 넘치면 다음 줄로 내리는 레이아웃
struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.sm
    var lineSpacing: CGFloat = Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let current = rows[rows.count - 1]
            let neededWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if neededWidth > maxWidth, !current.indices.isEmpty {
                rows.append(Row(indices: [index], width: size.width, height: size.height))
            } else {
                rows[rows.count - 1].indices.append(index)
                rows[rows.count - 1].width = neededWidth
                rows[rows.count - 1].height = max(current.height, size.height)
            }
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

#Preview {
    FlowLayout {
        ForEach(["# 앱개발", "# 코레일", "# 닭발", "# 밥 먹기", "# 카피바라 키우기 게임"], id: \.self) { tag in
            Text(tag)
                .padding(8)
                .background(Color.tsSurface2, in: Capsule())
        }
    }
    .padding()
}
