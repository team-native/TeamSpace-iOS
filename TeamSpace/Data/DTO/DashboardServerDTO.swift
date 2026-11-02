import Foundation

/// GET /dashboard/home (TeamSpace-backend develop `space.dashboard_home`)
/// `{ me, summary: { todoCount, todayTodoCount, unreadNotifications, receivedApprovalCount, notice, schedule },
///    todos, notifications, approvals, events, projects, finance?: { available, pools } }`
/// `finance` 는 재정 권한(FA)이 있을 때만 와요. 금액 흐름 · 수금은 /finance/summary 를 따로 불러요.
struct ServerDashboardHomeDTO: Decodable {
    let summary: Summary
    let notifications: [NotificationResponseDTO]
    let events: [ServerEventDTO]
    let projects: [ServerJoinedProjectDTO]
    let canSeeFinance: Bool

    struct Summary: Decodable {
        let todoCount: Int
        let todayTodoCount: Int
        let unreadNotifications: Int
        let notice: ServerNoticeItemDTO?

        private enum CodingKeys: String, CodingKey { case todoCount, todayTodoCount, unreadNotifications, notice }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            todoCount = container.money(.todoCount)
            todayTodoCount = container.money(.todayTodoCount)
            unreadNotifications = container.money(.unreadNotifications)
            notice = try? container.decodeIfPresent(ServerNoticeItemDTO.self, forKey: .notice)
        }
    }

    private enum CodingKeys: String, CodingKey { case summary, notifications, events, projects, finance }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        summary = try container.decode(Summary.self, forKey: .summary)
        notifications = Self.lossy(container, .notifications)
        events = Self.lossy(container, .events)
        projects = Self.lossy(container, .projects)
        canSeeFinance = container.contains(.finance) && (try? container.decodeNil(forKey: .finance)) == false
    }

    /// 한 항목이 깨져도 나머지는 보여줘요.
    private static func lossy<T: Decodable>(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> [T] {
        ((try? container.decodeIfPresent([LossyItem<T>].self, forKey: key)) ?? []).compactMap(\.value)
    }

    var latestNotification: DashboardNotificationPreview? {
        notifications.first.map { item in
            let dto = item.toEntity()
            return DashboardNotificationPreview(
                type: dto.type, title: dto.title, subtitle: dto.message ?? dto.type.dashboardLabel, createdAt: dto.createdAt
            )
        }
    }

    /// 지난 일정은 빼고 가까운 순서로 보여줘요.
    func schedules(now: Date = Date()) -> [ScheduleItem] {
        events.compactMap { event -> ScheduleItem? in
            guard let period = event.period, period.end >= now else { return nil }
            let place = [event.place, event.host].compactMap { $0 }.first { !$0.isEmpty } ?? ""
            return ScheduleItem(id: event.id, title: event.title, place: place, startsAt: period.start)
        }
    }

    func toEntity(finance: FinanceSummary?, contracts: ContractSummary?, notices: [NoticePreview]?) -> DashboardHome {
        DashboardHome(
            todayTaskCount: summary.todayTodoCount,
            unreadNotificationCount: summary.unreadNotifications,
            latestNotification: latestNotification,
            finance: finance,
            contracts: contracts,
            projects: projects.map { $0.toProjectProgress() },
            schedules: schedules(),
            notices: notices ?? summary.notice.map { [$0.toPreview()] } ?? []
        )
    }
}

private struct LossyItem<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

private extension NotificationType {
    /// 서버 알림에 본문이 없어서 홈 카드 둘째 줄에 분류를 써요.
    var dashboardLabel: String {
        switch self {
        case .approval: return "내 업무 · 결재 요청"
        case .approvalResult: return "내 업무 · 결재"
        case .finance: return "재정"
        case .schedule: return "일정"
        case .rule: return "제도 · 규칙 변경"
        case .notice: return "공지"
        case .inquiryAnswer: return "내 문의 · 답변"
        case .unknown: return "알림"
        }
    }
}

extension ServerJoinedProjectDTO {
    /// 02-1 홈 진행 중인 프로젝트 — 마감은 `due`("11.20 납품"), 없으면 `desc` 기간의 끝
    func toProjectProgress(calendar: Calendar = .current) -> ProjectProgress {
        let period = desc.components(separatedBy: " · ").last.flatMap { ServerProjectDTO.period($0, calendar: calendar) }
        let endYear = period?.1.map { calendar.component(.year, from: $0) }
        return ProjectProgress(
            id: id,
            name: name,
            memberCount: memberCount,
            dueDate: ServerProjectDTO.dueDate(due.isEmpty ? nil : due, year: endYear, calendar: calendar) ?? period?.1,
            progress: min(max(progress, 0), 100)
        )
    }
}

extension ServerNoticeItemDTO {
    func toPreview() -> NoticePreview {
        let summary = toEntity()
        return NoticePreview(id: summary.id, category: summary.category, title: summary.title, updatedAt: summary.updatedAt)
    }
}

extension ServerFinanceSummaryDTO {
    /// 02-1 홈 재정 카드 — 보유금은 세 풀의 합이에요.
    func toHomeFinance(now: Date = Date(), calendar: Calendar = .current) -> FinanceSummary {
        let overview = toOverview(month: now, now: now, calendar: calendar)
        let pools = self.pools.map { $0.toEntity() }
        return FinanceSummary(
            month: now,
            availableAmount: summary.available,
            holdingAmount: pools.reduce(0) { $0 + $1.amount },
            changeRate: overview.changeRate,
            trend: monthlyFlows(calendar: calendar).sorted { $0.month < $1.month }.map(\.income),
            pools: pools,
            monthIncome: summary.monthlyRevenue,
            monthExpense: summary.monthlyExpense
        )
    }

    /// 02-1 홈 외주 계약 카드 — 서버에 계약 목록이 없어 올해 수금 내역으로 보여줘요.
    func toHomeContracts(now: Date = Date(), calendar: Calendar = .current) -> ContractSummary {
        let year = calendar.component(.year, from: now)
        // 요약의 수금 내역에는 id 가 없을 수 있어 순서로 번호를 매겨요.
        let thisYear = receipts.enumerated()
            .compactMap { index, receipt in receipt.day.map { (receipt, $0, receipt.id ?? index + 1) } }
            .filter { calendar.component(.year, from: $0.1) == year }
            .sorted { $0.1 > $1.1 }
        let contracts = thisYear.prefix(2).map { receipt, day, id in
            Contract(
                id: id, title: receipt.project, amount: receipt.amount, contractedAt: day,
                status: receipt.isCollected ? .completed : .contracted
            )
        }
        let deposits = thisYear.filter { $0.0.isCollected }.prefix(2).map { receipt, day, id in
            Deposit(id: id, title: receipt.project, kind: receipt.client, amount: receipt.amount, paidAt: day)
        }
        return ContractSummary(
            totalAmount: thisYear.reduce(0) { $0 + $1.0.amount },
            yearCount: thisYear.count,
            pools: pools.map { $0.toEntity() },
            recentContracts: Array(contracts),
            recentDeposits: Array(deposits)
        )
    }
}
