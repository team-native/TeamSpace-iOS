import Foundation

struct CheckNotificationPermissionUseCase {
    private let permissionRepository: NotificationPermissionRepository

    init(permissionRepository: NotificationPermissionRepository) {
        self.permissionRepository = permissionRepository
    }

    func execute() async -> NotificationPermissionStatus {
        await permissionRepository.currentStatus()
    }
}
