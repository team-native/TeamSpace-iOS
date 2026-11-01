import SwiftUI

/// COMMON-02 목록 맨 아래 — 닿으면 다음 페이지를 불러오고, 실패하면 다시 불러오기를 보여줘요.
/// 마지막 페이지면 아무것도 그리지 않아요.
struct LoadMoreFooter: View {
    let paging: PagingState
    /// 실패 카드 보조 문구 — 예: "위의 알림은 그대로 볼 수 있어요."
    var failureHint: String = "위의 목록은 그대로 볼 수 있어요."
    /// false 면 끝에 닿아도 자동으로 부르지 않고 "더 보기" 버튼을 보여줘요. (아래에 다른 카드가 있는 화면)
    var loadsAutomatically: Bool = true
    var moreTitle: String = "더 보기"
    let onLoadMore: () -> Void

    var body: some View {
        if paging.didFail {
            failedRow
        } else if !loadsAutomatically, paging.hasMore, !paging.isLoading {
            moreButton
        } else if !loadsAutomatically, paging.isLoading {
            loadingRow
        } else if paging.hasMore {
            loadingRow
                // 커서가 바뀔 때마다(한 페이지 받을 때마다) 다시 확인해요 — 목록이 짧아 바로 보여도 이어서 불러와요.
                .task(id: paging.nextCursor) {
                    guard !paging.isLoading else { return }
                    onLoadMore()
                }
        }
    }

    /// Figma 14-3 목록 끝 · 더 불러오는 중
    private var loadingRow: some View {
        HStack(spacing: Spacing.sm) {
            SpinningLoader()
            Text("더 불러오는 중이에요")
                .tsFont(.footnoteBold)
                .foregroundStyle(Color.tsPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .accessibilityElement(children: .combine)
    }

    private var moreButton: some View {
        Button(moreTitle, action: onLoadMore)
            .buttonStyle(.tsSecondary)
    }

    /// Figma 14-4 목록 끝 · 다음 목록 불러오기 실패
    private var failedRow: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("다음 목록을 불러오지 못했어요")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk)
                Text(failureHint)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button(action: onLoadMore) {
                Text("다시 불러오기")
                    .tsFont(.footnoteBold)
                    .foregroundStyle(Color.tsInk2)
                    .padding(.horizontal, Spacing.lg + Spacing.xxxs)
                    .frame(minHeight: 38)
                    .background(Color.tsSurface2, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
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
