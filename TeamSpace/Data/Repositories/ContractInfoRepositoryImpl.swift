import Foundation

final class ContractInfoRepositoryImpl: ContractInfoRepository, @unchecked Sendable {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func create(project: String, _ draft: ContractInfoDraft) async throws {
        let body = ServerContractWriteRequestDTO(
            project: project,
            pm: draft.pm.trimmed,
            signed: draft.signedText(),
            total: draft.total,
            collected: draft.collected ?? 0,
            step: draft.step,
            staff: draft.staff.trimmed,
            split: draft.split.trimmed,
            next: draft.next.trimmed
        )
        try await send(Endpoint(method: .post, path: "admin/finance/contracts", body: body))
    }

    func update(project: String, changes: ContractInfoChanges) async throws {
        let body = ServerContractWriteRequestDTO(
            pm: changes.pm, signed: changes.signed, total: changes.total, collected: changes.collected,
            step: changes.step, staff: changes.staff, split: changes.split, next: changes.next
        )
        // 프로젝트 이름(공백 · 한글)은 APIClient 가 경로를 인코딩해요.
        try await send(Endpoint(method: .patch, path: "admin/finance/contracts/\(project)", body: body))
    }

    private func send(_ endpoint: Endpoint) async throws {
        do {
            _ = try await client.request(endpoint, as: EmptyResponseDTO.self)
        } catch let error as NetworkError {
            throw error.asAppError
        }
    }
}

/// POST · PATCH /admin/finance/contracts 요청 — 비운 값은 보내지 않아요.
struct ServerContractWriteRequestDTO: Codable, Equatable {
    var project: String?
    var pm: String?
    var signed: String?
    var total: Int?
    var collected: Int?
    var step: Int?
    var staff: String?
    var split: String?
    var next: String?
}

private extension String {
    /// 앞뒤 공백을 빼고, 비면 nil
    var trimmed: String? {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
