import SwiftUI

/// 카드 안 행 사이 구분선
struct TSDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.tsLine)
            .frame(height: 1)
    }
}

#Preview {
    TSDivider().padding()
}
