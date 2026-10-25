import SwiftUI

/// 04-7 재정 제한 권한 (NativeLab 재정)
struct FinanceAccessView: View {
    @State private var viewModel: FinanceAccessViewModel
    private let onNavigate: (AppRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: FinanceAccessViewModel, onNavigate: @escaping (AppRoute) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("정보 확인과 권한")
                        .tsFont(.micro)
                        .foregroundStyle(Color.tsPrimary)
                    StatusBadge(title: viewModel.scopeBadge, tone: .primary)
                    Text("팀의 성과는 함께,\n민감 정보는 안전하게")
                        .tsFont(.title3)
                        .foregroundStyle(Color.tsInk)
                        .accessibilityAddTraits(.isHeader)
                }
                InfoBanner(
                    message: "아래 공개 범위는 데모 정책이에요. 실제 재정 공개 기준은 운영 확정이 필요해요.",
                    icon: .infoCircle,
                    style: .muted
                )
                summary
                RestrictedInfoCard()
                FinanceAlertPolicyCard()
                actions
            }
            .padding(.horizontal, Spacing.screen)
            .padding(.bottom, Spacing.xxxl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            TSNavigationBar(title: "NativeLab 재정", onBack: { dismiss() })
                .padding(.horizontal, Spacing.screen)
                .padding(.bottom, Spacing.sm)
                .background(Color.tsBackground)
        }
        .background(Color.tsBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var summary: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, minHeight: 160)
        case .empty, .forbidden:
            EmptyView()
        case .failed(let error):
            RetryView(message: error.userMessage) { Task { await viewModel.load() } }
        case .loaded(let ledger):
            PublicSummaryCard(year: viewModel.year, total: ledger.totalAmount, latest: viewModel.latestCollected)
        }
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button("공개 범위 · 내 권한 확인") { onNavigate(.comingSoon(title: "내 권한 · 접근 범위")) }
                .buttonStyle(.ts(.secondary, size: .medium))
            if viewModel.canRequestAccess {
                Button("FA에 접근 권한 문의") { onNavigate(.comingSoon(title: "문의 · 건의")) }
                    .buttonStyle(.ts(.primary, size: .medium))
            }
        }
    }
}

/// 구성원 공개 요약
private struct PublicSummaryCard: View {
    let year: Int
    let total: Int
    let latest: FinanceContract?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("구성원 공개 요약")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("\(String(year))년 누적 수주 · 표본")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                Text(TSFormat.won(total))
                    .tsFont(.amount)
                    .foregroundStyle(Color.tsInk)
            }
            if let latest {
                SmallKeyValueRow(title: "최근 수주", value: "\(latest.name) · \(TSFormat.won(latest.amount))")
                SmallKeyValueRow(title: "확인일", value: TSFormat.fullDate(latest.collectedAt))
            }
            Text("누적 수주는 계약 기준이며, 실제 입금 합계나 사용 가능한 잔액과는 달라요.")
                .tsFont(.caption)
                .foregroundStyle(Color.tsInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tsCard()
    }
}

/// 현재 계정에서 제한된 정보
private struct RestrictedInfoCard: View {
    private let items: [(title: String, badge: String)] = [
        ("계좌 정보", "•••-••••-••••"),
        ("계약 원문", "권한 필요"),
        ("개별 배분금", "금액 비공개")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("현재 계정에서 제한된 정보")
                .tsFont(.bodyBold)
                .foregroundStyle(Color.tsInk)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: Spacing.sm) {
                    TSIcon.lock.sized(.base)
                        .foregroundStyle(Color.tsInk3)
                    Text(item.title)
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk2)
                    Spacer()
                    StatusBadge(title: item.badge, tone: .neutral)
                }
                .accessibilityElement(children: .combine)
            }
            Text("권한 밖 원문·계좌·개인별 금액은 조회하거나 다운로드할 수 없어요. 비공개 숫자를 합계로 추정할 수 있는 세부 내역도 제공하지 않아요.")
                .tsFont(.caption2)
                .foregroundStyle(Color.tsInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tsCard()
    }
}

/// 재정 알림은 수주 · 입금만
private struct FinanceAlertPolicyCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("재정 알림은 수주·입금만")
                    .tsFont(.bodyBold)
                    .foregroundStyle(Color.tsInk)
                Text("새 수주와 입금 발생을 알려드려요. 출금·지출 푸시는 보내지 않아요. 알림에서도 계정의 공개 범위를 적용해요.")
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            TSIcon.bell.sized(.xl)
                .foregroundStyle(Color.tsPrimary)
        }
        .padding(Spacing.card)
        .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Color.tsPrimarySoft))
    }
}

#Preview {
    NavigationStack {
        FinanceAccessView(
            viewModel: DIContainer.preview().makeFinanceAccessViewModel(user: AuthUser(id: 1, name: "옥물결", roles: [.member])),
            onNavigate: { _ in }
        )
    }
}
