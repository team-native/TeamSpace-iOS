import SwiftUI

/// 02-1 홈 본문 — 대시보드 응답을 카드별로 나눠 그립니다.
struct HomeSections: View {
    let home: DashboardHome
    @Binding var financeMode: HomeFinanceMode
    /// 선택한 기준(사용 가능 / 보유금)의 금액
    let financeAmount: Int
    let onNavigate: (AppRoute) -> Void
    let onSelectTab: (MainTab) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let latest = home.latestNotification {
                HomeNotificationBanner(notification: latest) { onNavigate(.notificationCenter) }
            }
            if let finance = home.finance {
                HomeFinanceCard(
                    finance: finance,
                    mode: $financeMode,
                    amount: financeAmount,
                    onDetail: { onSelectTab(.finance) }
                )
            }
            if let contracts = home.contracts {
                HomeContractCard(summary: contracts, onShowAll: { onSelectTab(.finance) })
            }
            if !home.projects.isEmpty {
                HomeProjectCard(projects: home.projects) {
                    onNavigate(.projects)
                }
            }
            if !home.schedules.isEmpty {
                HomeScheduleCard(schedules: home.schedules) {
                    onNavigate(.comingSoon(title: "캘린더"))
                }
            }
            if !home.notices.isEmpty {
                HomeNoticeList(notices: home.notices) {
                    onNavigate(.comingSoon(title: "공지"))
                }
            }
        }
    }
}

/// 02-1 최근 알림 배너 (`btn/notif-banner`)
struct HomeNotificationBanner: View {
    let notification: DashboardNotificationPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                IconTile(
                    icon: notification.type.icon,
                    tint: notification.type.tint,
                    background: notification.type.tileBackground
                )
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(notification.title)
                        .tsFont(.captionBold)
                        .foregroundStyle(Color.tsInk)
                    Text("\(notification.subtitle) · \(TSFormat.relative(notification.createdAt))")
                        .tsFont(.caption)
                        .foregroundStyle(Color.tsInk3)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                TSIcon.chevronRight.sized(.base)
                    .foregroundStyle(Color.tsInk3)
            }
            .padding(Spacing.md + Spacing.xxxs)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
