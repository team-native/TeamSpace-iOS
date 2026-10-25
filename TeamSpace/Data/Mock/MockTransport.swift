import Foundation

/// 서버 없이 개발하기 위한 가짜 서버. 명세서의 응답 예시를 그대로 돌려줍니다.
/// - 비밀번호 `wrong` → 401 (계정 불일치)
/// - 이메일 형식 오류 → 400 (errors[].reason)
/// - 그 외 → 200 로그인 성공 (이메일이 `fa` 로 시작하면 FA 권한 → 04-9 금액이 보여요)
/// - GET /users/me: Authorization 헤더가 없으면 401
/// - GET /notifications · PATCH /notifications/{id}/read: 읽음 상태를 메모리에 기억
/// - 계정 요청: 이메일이 `taken@` 으로 시작하면 409 (이미 요청됨)
/// - GET /users · /users/{id} · /organization/tree: Figma 03 팀원 예시 (MockMemberFixture)
/// - GET /documents/{id} · POST /approvals/{id}/decide · POST /documents/{id}/comments · withdraw
/// - GET /approvals/~: Figma 05 결재 예시 (MockApprovalStore, 처리 결과를 메모리에 기억)
/// - GET /finance/~: Figma 04 재무 예시 (MockFinanceFixture)
/// - GET /dashboard/home: Figma 02-1 홈 예시 (MockDashboardFixture)
/// - POST /notifications/push-token: Authorization 헤더가 없으면 401
struct MockTransport: HTTPTransport {
    static let baseURL = URL(fileURLWithPath: "/mock-api")
    static let failingPassword = "wrong"
    /// FA 계정으로 로그인했을 때 받는 가짜 토큰
    static let faToken = "mock-fa-token"

    var latencyNanoseconds: UInt64 = 700_000_000
    private let notificationStore = MockNotificationStore()
    private let approvalStore = MockApprovalStore()

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await Task.sleep(nanoseconds: latencyNanoseconds)
        let path = request.url?.lastPathComponent ?? ""
        if let response = try memberRoute(request, path: path) {
            return response
        }
        if let response = try financeRoute(request, path: path) {
            return response
        }
        if let response = try approvalRoute(request, path: path) {
            return response
        }
        switch (request.httpMethod, path) {
        case ("POST", "login"):
            return try login(request)
        case ("POST", "account-requests"):
            return try accountRequest(request)
        case ("GET", "notifications"):
            return try notifications(request)
        case ("PATCH", "read"):
            return try markRead(request)
        case ("GET", "me"):
            return try me(request)
        case ("GET", "home"):
            return try respond(request, status: 200, json: MockDashboardFixture.json())
        case ("POST", "push-token"):
            return try pushToken(request)
        case ("POST", "password-reset"):
            return try respond(request, status: 200, json: #"{"code":200,"message":"메일 발송 완료","data":{"success":true}}"#)
        default:
            return try respond(request, status: 404, json: #"{"code":404,"message":"Mock 에 없는 API 입니다."}"#)
        }
    }

    private func login(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(LoginRequestDTO.self, from: body)
        else {
            return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청 파라미터입니다."}"#)
        }
        if !dto.email.contains("@") {
            return try respond(request, status: 400, json: """
            {"code":400,"message":"잘못된 요청 파라미터입니다.","errors":[{"field":"email","reason":"이메일 형식이 올바르지 않습니다."}]}
            """)
        }
        if dto.password == Self.failingPassword {
            return try respond(request, status: 401, json: #"{"code":401,"message":"이메일 또는 비밀번호가 일치하지 않습니다."}"#)
        }
        let isFA = dto.email.lowercased().hasPrefix("fa")
        let token = isFA ? Self.faToken : "mock-access-token"
        let roles = isFA ? #"["FA"]"# : #"["Member"]"#
        return try respond(request, status: 200, json: """
        {"code":200,"message":"로그인 성공","data":{"accessToken":"\(token)","refreshToken":"mock-refresh-token",\
        "user":{"id":1,"name":"홍길동","roles":\(roles)}}}
        """)
    }

    private func notifications(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let payload = MockEnvelope(code: 200, message: "조회 성공", data: ["list": notificationStore.items()])
        return try respond(request, status: 200, json: String(decoding: try JSONEncoder().encode(payload), as: UTF8.self))
    }

    private func markRead(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let components = request.url?.pathComponents ?? []
        guard components.count >= 2, let id = Int(components[components.count - 2]), notificationStore.markRead(id: id) else {
            return try respond(request, status: 404, json: #"{"code":404,"message":"해당 알림을 찾을 수 없습니다."}"#)
        }
        return try respond(request, status: 200, json: #"{"code":200,"message":"읽음 처리 완료","data":{"success":true,"updatedId":\#(id)}}"#)
    }

    /// 05 결재 — /approvals/~ · /documents/~
    private func approvalRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard let url = request.url else { return nil }
        let components = url.pathComponents
        let parent = url.deletingLastPathComponent().lastPathComponent
        let notFound = #"{"code":404,"message":"해당 문서를 찾을 수 없습니다."}"#
        switch (request.httpMethod ?? "", path) {
        case ("GET", "mine") where components.contains("approvals"):
            return try respond(request, status: 200, json: approvalStore.listJSON(mine: true))
        case ("GET", "received") where components.contains("approvals"):
            return try respond(request, status: 200, json: approvalStore.listJSON(mine: false))
        case ("GET", _) where parent == "documents":
            guard let id = Int(path), let json = approvalStore.detailJSON(id: id) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("POST", "decide"):
            guard
                let id = Int(parent),
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(ApprovalDecisionRequestDTO.self, from: body)
            else { return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청입니다."}"#) }
            guard let json = approvalStore.decideJSON(approvalId: id, decision: dto.decision, comment: dto.comment) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("POST", "comments"):
            guard
                let id = Int(parent),
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(ApprovalCommentRequestDTO.self, from: body),
                let json = approvalStore.commentJSON(documentId: id, body: dto.body)
            else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 201, json: json)
        case ("POST", "documents"):
            guard
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(DocumentCreateRequestDTO.self, from: body)
            else { return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청입니다."}"#) }
            let json = approvalStore.createJSON(
                kind: dto.type,
                title: dto.title,
                amount: dto.amount,
                fields: dto.fields.map { ($0.title, $0.value) },
                reason: dto.reason
            )
            return try respond(request, status: 201, json: json)
        case ("POST", "submit"):
            guard let id = Int(parent), approvalStore.update(id: id, status: "PENDING") else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: #"{"code":200,"message":"제출 완료","data":{"success":true}}"#)
        case ("POST", "withdraw"):
            guard let id = Int(parent), approvalStore.update(id: id, status: "DRAFT") else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: #"{"code":200,"message":"요청 취소 완료","data":{"success":true}}"#)
        default:
            return nil
        }
    }

    /// 04 재무 — GET /finance/~
    private func financeRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard
            request.httpMethod == "GET",
            let url = request.url,
            url.pathComponents.contains("finance")
        else { return nil }
        let month = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "month" }?.value
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        switch path {
        case "overview":
            return try respond(request, status: 200, json: MockFinanceFixture.overview(monthText: month))
        case "flows":
            let to = query?.first { $0.name == "to" }?.value
            let count = query?.first { $0.name == "months" }?.value
            return try respond(request, status: 200, json: MockFinanceFixture.flows(toText: to, countText: count))
        case "projects":
            let year = query?.first { $0.name == "year" }?.value
            let isFA = request.value(forHTTPHeaderField: "Authorization")?.contains(Self.faToken) == true
            return try respond(request, status: 200, json: MockFinanceFixture.projects(yearText: year, isFA: isFA))
        case "contracts":
            let year = query?.first { $0.name == "year" }?.value
            return try respond(request, status: 200, json: MockFinanceFixture.ledger(yearText: year))
        default:
            guard url.deletingLastPathComponent().lastPathComponent == "contracts", let id = Int(path) else { return nil }
            guard let json = MockFinanceFixture.contractDetail(id: id) else {
                return try respond(request, status: 404, json: #"{"code":404,"message":"해당 수주를 찾을 수 없습니다."}"#)
            }
            return try respond(request, status: 200, json: json)
        }
    }

    /// 03 팀원 — GET /users, /users/{id}, /organization/tree
    private func memberRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard request.httpMethod == "GET" else { return nil }
        let parent = request.url?.deletingLastPathComponent().lastPathComponent
        let body: Data?
        if path == "users" {
            body = MockMemberFixture.list()
        } else if parent == "users", let id = Int(path) {
            body = MockMemberFixture.detail(id: id)
        } else if parent == "organization", path == "tree" {
            body = MockMemberFixture.tree()
        } else {
            return nil
        }
        guard let body else {
            return try respond(request, status: 404, json: #"{"code":404,"message":"해당 팀원을 찾을 수 없습니다."}"#)
        }
        return try respond(request, status: 200, json: String(decoding: body, as: UTF8.self))
    }

    private func pushToken(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            return try respond(request, status: 401, json: #"{"code":401,"message":"유효하지 않거나 만료된 토큰입니다. 로그인해 주세요."}"#)
        }
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(PushTokenRequestDTO.self, from: body),
            !dto.token.isEmpty
        else {
            return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청 파라미터입니다."}"#)
        }
        return try respond(request, status: 200, json: #"{"code":200,"message":"등록 완료","data":{"success":true}}"#)
    }

    private func me(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            return try respond(request, status: 401, json: #"{"code":401,"message":"유효하지 않거나 만료된 토큰입니다. 로그인해 주세요."}"#)
        }
        let isFA = request.value(forHTTPHeaderField: "Authorization")?.contains(Self.faToken) == true
        let department = isFA ? "FA" : "NativeOps"
        let roles = isFA ? #"["FA"]"# : #"["Member","PM"]"#
        return try respond(request, status: 200, json: """
        {"code":200,"message":"조회 성공","data":{"id":1,"name":"홍길동","email":"s00000@gsm.hs.kr",\
        "department":"\(department)","roles":\(roles)}}
        """)
    }

    private func accountRequest(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(AccountRequestRequestDTO.self, from: body)
        else {
            return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청 파라미터입니다."}"#)
        }
        if dto.email.hasPrefix("taken@") {
            return try respond(request, status: 409, json: #"{"code":409,"message":"이미 요청된 이메일입니다."}"#)
        }
        let payload = MockEnvelope(
            code: 201,
            message: "요청 완료",
            data: MockAccountRequestData(
                name: dto.name,
                email: dto.email,
                department: dto.department,
                status: "REVIEWING",
                requestedAt: ISO8601DateFormatter().string(from: Date())
            )
        )
        let data = try JSONEncoder().encode(payload)
        return try respond(request, status: 201, json: String(decoding: data, as: UTF8.self))
    }

    private func respond(_ request: URLRequest, status: Int, json: String) throws -> (Data, HTTPURLResponse) {
        guard
            let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else {
            throw URLError(.badURL)
        }
        return (Data(json.utf8), response)
    }
}

private struct MockEnvelope<T: Encodable>: Encodable {
    let code: Int
    let message: String
    let data: T
}

private struct MockAccountRequestData: Encodable {
    let name: String
    let email: String
    let department: String
    let status: String
    let requestedAt: String
}

/// Mock 알림 — Figma 02-2 · 02-3 · 02-4 알림 센터 예시 내용
private final class MockNotificationStore: @unchecked Sendable {
    struct Item: Encodable {
        let id: Int
        let type: String
        let title: String
        let message: String
        let deepLink: String?
        var isRead: Bool
        let createdAt: String
        var effectiveAt: String?
    }

    private let lock = NSLock()
    private var storage: [Item]

    init(now: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        func ago(_ seconds: TimeInterval) -> String { formatter.string(from: now.addingTimeInterval(-seconds)) }
        func later(days: Double) -> String { formatter.string(from: now.addingTimeInterval(days * 86_400)) }
        storage = [
            Item(id: 101, type: "APPROVAL", title: "새 결재 요청이 도착했어요",
                 message: "이시우 님이 Book-on 프로젝트 인력 지원(iOS 1명)을 요청했어요.",
                 deepLink: "/approvals/12", isRead: false, createdAt: ago(30)),
            Item(id: 102, type: "FINANCE", title: "외주 입금이 확인됐어요",
                 message: "BRIDGE · iOS 앱 프로토타입  +3,600,000원",
                 deepLink: "/finance", isRead: false, createdAt: ago(32 * 60)),
            Item(id: 103, type: "SCHEDULE", title: "디자인 리뷰 시간이 바뀌었어요",
                 message: "10월 14일(화) 14:00 → 15:00 · 온라인",
                 deepLink: nil, isRead: false, createdAt: ago(2 * 3_600)),
            Item(id: 107, type: "INQUIRY_ANSWER", title: "내 문의에 답변이 도착했어요",
                 message: "활동 보고서 제출 기한은 다음 주 금요일까지 연장했어요. 자세한 내용은 공식 답변을 확인해 주세요.",
                 deepLink: "/inquiries/42", isRead: false, createdAt: ago(3 * 3_600)),
            Item(id: 104, type: "RULE", title: "프로젝트 운영 원칙이 개정됐어요",
                 message: "제안 검토 기한이 3주에서 2주로 바뀌어요. 시행 전에 달라진 조항을 확인해 주세요!",
                 deepLink: "/rules/3", isRead: false, createdAt: ago(1 * 86_400), effectiveAt: later(days: 5)),
            Item(id: 108, type: "RULE", title: "프로젝트 문서 분류 안내",
                 message: "문서 분류 기준이 정리됐어요.",
                 deepLink: "/rules/4", isRead: true, createdAt: ago(6 * 86_400), effectiveAt: ago(2 * 86_400)),
            Item(id: 105, type: "NOTICE", title: "10월 정기 회의 장소 안내",
                 message: "이번 달 회의는 4층 홈베이스에서 진행해요.",
                 deepLink: "/posts/77", isRead: true, createdAt: ago(4 * 86_400)),
            Item(id: 106, type: "APPROVAL_RESULT", title: "비용 승인 요청이 승인됐어요",
                 message: "Book-on 테스트 기기 구매 · 420,000원",
                 deepLink: "/documents/55", isRead: true, createdAt: ago(5 * 86_400))
        ]
    }

    func items() -> [Item] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func markRead(id: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let index = storage.firstIndex(where: { $0.id == id }) else { return false }
        storage[index].isRead = true
        return true
    }
}
