import Foundation
import Observation

/// 02-2 알림 센터
@Observable
@MainActor
final class NotificationCenterViewModel {
    private(set) var state: ViewState<[AppNotification]> = .idle
    var filter: NotificationFilter = .all
    /// 읽음 처리 실패 등 화면 아래 짧게 보여줄 메시지
    var toastMessage: String?

    private let fetchNotificationsUseCase: FetchNotificationsUseCase
    private let markNotificationsReadUseCase: MarkNotificationsReadUseCase

    init(
        fetchNotificationsUseCase: FetchNotificationsUseCase,
        markNotificationsReadUseCase: MarkNotificationsReadUseCase
    ) {
        self.fetchNotificationsUseCase = fetchNotificationsUseCase
        self.markNotificationsReadUseCase = markNotificationsReadUseCase
    }

    let filters = NotificationFilter.allCases

    private var notifications: [AppNotification] {
        state.value ?? []
    }

    var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }

    /// 필터 칩 옆 숫자 — 안 읽은 개수 (0이면 표시 안 함)
    func unreadCount(for filter: NotificationFilter) -> Int? {
        let count = notifications.filter { filter.matches($0) && !$0.isRead }.count
        return count > 0 ? count : nil
    }

    /// 오늘 / 이번 주 / 이전
    func sections(now: Date = Date(), calendar: Calendar = .current) -> [NotificationSection] {
        let filtered = notifications.filter { filter.matches($0) }
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let today = filtered.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
        let thisWeek = filtered.filter { !calendar.isDate($0.createdAt, inSameDayAs: now) && $0.createdAt >= weekAgo }
        let older = filtered.filter { $0.createdAt < weekAgo }
        return [
            NotificationSection(id: "today", title: "오늘", items: today),
            NotificationSection(id: "week", title: "이번 주", items: thisWeek),
            NotificationSection(id: "older", title: "이전", items: older)
        ]
        .filter { !$0.items.isEmpty }
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let result = try await fetchNotificationsUseCase.execute()
            state = result.isEmpty ? .empty : .loaded(result)
        } catch {
            AppLog.record(error, context: "notificationCenter.load")
            state = .failed(error)
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        await markAsRead(ids: [notification.id])
    }

    func markAllAsRead() async {
        await markAsRead(ids: notifications.filter { !$0.isRead }.map(\.id))
    }

    /// 화면에 먼저 반영하고, 실패한 것만 되돌립니다.
    private func markAsRead(ids: [Int]) async {
        guard !ids.isEmpty else { return }
        apply(readIds: Set(ids), isRead: true)
        let result = await markNotificationsReadUseCase.execute(ids: ids)
        let failed = Set(ids).subtracting(result.succeeded)
        if let failure = result.failure, !failed.isEmpty {
            AppLog.record(failure, context: "notificationCenter.markAsRead")
            apply(readIds: failed, isRead: false)
            toastMessage = failure.userMessage
        }
    }

    private func apply(readIds: Set<Int>, isRead: Bool) {
        let updated = notifications.map { item -> AppNotification in
            var copy = item
            if readIds.contains(item.id) { copy.isRead = isRead }
            return copy
        }
        state = .loaded(updated)
    }
}
