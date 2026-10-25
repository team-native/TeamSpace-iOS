import Foundation

/// GET /dashboard/home 응답의 `data`
/// 명세서에 응답 예시가 없어 Figma 02-1 홈 화면 기준으로 정했습니다. (백엔드와 맞춰야 함)
struct DashboardHomeResponseDTO: Decodable {
    let todayTaskCount: Int
    let unreadNotificationCount: Int
    let latestNotification: LatestNotificationDTO?
    let finance: FinanceSummaryDTO?
    let contracts: ContractSummaryDTO?
    let projects: [ProjectProgressDTO]
    let schedules: [ScheduleItemDTO]
    let notices: [NoticePreviewDTO]

    func toEntity() -> DashboardHome {
        DashboardHome(
            todayTaskCount: todayTaskCount,
            unreadNotificationCount: unreadNotificationCount,
            latestNotification: latestNotification?.toEntity(),
            finance: finance?.toEntity(),
            contracts: contracts?.toEntity(),
            projects: projects.map { $0.toEntity() },
            schedules: schedules.map { $0.toEntity() },
            notices: notices.map { $0.toEntity() }
        )
    }
}

struct LatestNotificationDTO: Decodable {
    let type: NotificationType
    let title: String
    let subtitle: String
    let createdAt: Date

    func toEntity() -> DashboardNotificationPreview {
        DashboardNotificationPreview(type: type, title: title, subtitle: subtitle, createdAt: createdAt)
    }
}

struct FinancePoolDTO: Decodable {
    let kind: FinancePoolKind
    let ratio: Int
    let amount: Int
    let count: Int?

    func toEntity() -> FinancePool {
        FinancePool(kind: kind, ratio: ratio, amount: amount, count: count)
    }
}

struct FinanceSummaryDTO: Decodable {
    let month: Date
    let availableAmount: Int
    let holdingAmount: Int
    let changeRate: Double
    let trend: [Int]
    let pools: [FinancePoolDTO]
    let monthIncome: Int
    let monthExpense: Int

    func toEntity() -> FinanceSummary {
        FinanceSummary(
            month: month,
            availableAmount: availableAmount,
            holdingAmount: holdingAmount,
            changeRate: changeRate,
            trend: trend,
            pools: pools.map { $0.toEntity() },
            monthIncome: monthIncome,
            monthExpense: monthExpense
        )
    }
}

struct ContractDTO: Decodable {
    let id: Int
    let title: String
    let amount: Int
    let contractedAt: Date
    let status: ContractStatus

    func toEntity() -> Contract {
        Contract(id: id, title: title, amount: amount, contractedAt: contractedAt, status: status)
    }
}

struct DepositDTO: Decodable {
    let id: Int
    let title: String
    let kind: String
    let amount: Int
    let paidAt: Date

    func toEntity() -> Deposit {
        Deposit(id: id, title: title, kind: kind, amount: amount, paidAt: paidAt)
    }
}

struct ContractSummaryDTO: Decodable {
    let totalAmount: Int
    let yearCount: Int
    let pools: [FinancePoolDTO]
    let recentContracts: [ContractDTO]
    let recentDeposits: [DepositDTO]

    func toEntity() -> ContractSummary {
        ContractSummary(
            totalAmount: totalAmount,
            yearCount: yearCount,
            pools: pools.map { $0.toEntity() },
            recentContracts: recentContracts.map { $0.toEntity() },
            recentDeposits: recentDeposits.map { $0.toEntity() }
        )
    }
}

struct ProjectProgressDTO: Decodable {
    let id: Int
    let name: String
    let memberCount: Int
    let dueDate: Date
    let progress: Int

    func toEntity() -> ProjectProgress {
        ProjectProgress(id: id, name: name, memberCount: memberCount, dueDate: dueDate, progress: min(max(progress, 0), 100))
    }
}

struct ScheduleItemDTO: Decodable {
    let id: Int
    let title: String
    let place: String
    let startsAt: Date

    func toEntity() -> ScheduleItem {
        ScheduleItem(id: id, title: title, place: place, startsAt: startsAt)
    }
}

struct NoticePreviewDTO: Decodable {
    let id: Int
    let category: NoticeCategory
    let title: String
    let updatedAt: Date

    func toEntity() -> NoticePreview {
        NoticePreview(id: id, category: category, title: title, updatedAt: updatedAt)
    }
}
