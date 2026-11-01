import Foundation

struct RequestNotificationPermissionUseCase {
    private let permissionRepository: NotificationPermissionRepository

    init(permissionRepository: NotificationPermissionRepository) {
        self.permissionRepository = permissionRepository
    }

    func execute() async throws -> NotificationPermissionStatus {
        try await permissionRepository.requestAuthorization()
    }
}
