import SwiftUI

/// COMMON-02 목록 맨 아래 — 닿으면 다음 페이지를 불러오고, 실패하면 다시 불러오기를 보여줘요.
/// 마지막 페이지면 아무것도 그리지 않아요.
struct LoadMoreFooter: View {
    let paging: PagingState
    let onLoadMore: () -> Void

    var body: some View {
        if paging.didFail {
            failedRow
        } else if paging.hasMore {
            loadingRow
                // 커서가 바뀔 때마다(한 페이지 받을 때마다) 다시 확인해요 — 목록이 짧아 바로 보여도 이어서 불러와요.
                .task(id: paging.nextCursor) {
                    guard !paging.isLoading else { return }
                    onLoadMore()
                }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: Spacing.sm) {
            SpinningLoader()
            Text("더 불러오는 중이에요")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .accessibilityElement(children: .combine)
    }

    private var failedRow: some View {
        VStack(spacing: Spacing.xs) {
            Text("다음 목록을 불러오지 못했어요")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
            Button(action: onLoadMore) {
                Text("다시 불러오기")
                    .tsFont(.captionBold)
                .foregroundStyle(Color.tsPrimary)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        LoadMoreFooter(paging: PagingState(nextCursor: "20"), onLoadMore: {})
        LoadMoreFooter(
            paging: {
                var paging = PagingState(nextCursor: "20")
                _ = paging.begin()
                paging.fail()
                return paging
            }(),
            onLoadMore: {}
        )
    }
    .padding()
    .background(Color.tsBackground)
}
