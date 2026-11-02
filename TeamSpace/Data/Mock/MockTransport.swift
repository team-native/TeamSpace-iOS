import Foundation

/// 서버 없이 개발하기 위한 가짜 서버. 명세서의 응답 예시를 그대로 돌려줍니다.
/// - 비밀번호 `wrong` → 401 (계정 불일치)
/// - 이메일 형식 오류 → 400 (errors[].reason)
/// - 그 외 → 200 로그인 성공 (이메일이 `fa` 로 시작하면 FA 권한 → 04-9 금액이 보여요)
/// - GET /users/me: Authorization 헤더가 없으면 401
/// - GET /notifications · POST /notifications/read: 읽음 상태를 메모리에 기억 (서버 develop 형식)
/// - 계정 요청: 이메일이 `taken@` 으로 시작하면 409 (이미 요청됨)
/// - GET /users · /users/{id} · /organization/tree: Figma 03 팀원 예시 (MockMemberFixture)
/// - GET · POST /approvals · GET /approvals/{id} · POST approve · reject · cancel · comments:
///   Figma 05 결재 · 07-4 · 07-5 내 문서 예시 (MockApprovalStore, 서버 develop 형식, 처리 결과를 메모리에 기억)
/// - GET /finance/summary · receipts · contracts/{project}: Figma 04 재무 (MockFinanceFixture, 서버 develop 형식, FA 아니면 403)
/// - GET /dashboard/home: Figma 02-1 홈 예시 (MockDashboardFixture)
/// - GET /docs · /docs/{slug} · /docs/{slug}/history · POST /docs/{slug}/read: Figma 06 문서함 · 09 규칙 (MockDocStore, 서버 develop 형식)
/// - GET /me/summary · /me/projects: Figma 07 내 공간 예시 (서버 develop 형식, 홈은 여러 API 를 조합)
/// - GET · POST /todos · PATCH /todos/{id}: Figma 07-2 (MockTodoStore, 서버 develop 형식, 메모리에 기억)
/// - GET /events · POST /events/{id}/rsvp: Figma 07-7 ~ 07-9 (MockScheduleStore, 서버 develop 형식, 참석 응답 기억)
/// - GET /me/activity: Figma 07-10 댓글 (MockActivityFixture, 서버 develop 형식) · 내 글 · 제안은 /posts · /proposals 의 mine
/// - GET · PATCH /me: Figma 07-13 (MockProfileStore, 서버 develop 형식, 저장 내용 기억)
/// - /projects/~ · /applications/~: Figma 08 (MockProjectStore, 신청 · 결과 등록 기억)
/// - /proposals/~: Figma 12 운영 제안 (MockProposalStore, 제안 · 추천 · 댓글 기억)
/// - /inquiries/~: Figma 11 익명 문의 · 담당자 받은함 (MockInquiryStore, 제출 · 배정 · 답변 기억)
/// - /notices/~: Figma 10-5 ~ 10-7 공지 (MockNoticeStore, 확인 · 게시 기억)
/// - /posts/~: Figma 10 팀 게시판 (MockBoardStore, 글 · 댓글 · 공감 · 신고 · 삭제 기억)
/// - GET /search: Figma 13 통합 검색 (MockSearchFixture)
/// - POST /notifications/push-token: Authorization 헤더가 없으면 401
struct MockTransport: HTTPTransport {
    static let baseURL = URL(fileURLWithPath: "/mock-api")
    static let failingPassword = "wrong"
    /// FA 계정으로 로그인했을 때 받는 가짜 토큰
    static let faToken = "mock-fa-token"
    /// 만료된 액세스 토큰 — 이 토큰으로 부르면 401, `/auth/refresh` 로 갱신하면 돼요.
    static let expiredAccessToken = "mock-expired-access-token"
    /// 만료된 리프레시 토큰 — `/auth/refresh` 가 401
    static let expiredRefreshToken = "mock-expired-refresh-token"
    private static let unauthorizedDetail = #"{"detail":"유효하지 않거나 만료된 토큰입니다. 로그인해 주세요."}"#

    var latencyNanoseconds: UInt64 = 700_000_000
    private let notificationStore = MockNotificationStore()
    private let approvalStore = MockApprovalStore()
    private let todoStore = MockTodoStore()
    private let scheduleStore = MockScheduleStore()
    private let profileStore = MockProfileStore()
    private let projectStore = MockProjectStore()
    private let docStore = MockDocStore()
    let boardStore = MockBoardStore()
    private let inquiryStore = MockInquiryStore()
    private let proposalStore = MockProposalStore()

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
        if let response = try projectRoute(request, path: path) {
            return response
        }
        switch (request.httpMethod, path) {
        case ("POST", "login"):
            return try login(request)
        case ("POST", "signup-requests"):
            return try accountRequest(request)
        case ("GET", "notifications"):
            return try notifications(request)
        case ("POST", "read") where request.url?.pathComponents.contains("notifications") == true:
            return try markRead(request)
        case ("POST", "refresh"):
            return try refresh(request)
        case ("GET", "me"):
            return try me(request)
        case ("GET", "home"):
            return try respond(request, status: 200, json: MockDashboardFixture.json())
        case ("POST", "push-token"):
            return try pushToken(request)
        case ("POST", "password-reset-requests"):
            return try respond(request, status: 202, json: #"{"accepted":true}"#)
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
            return try respond(request, status: 401, json: #"{"detail":"이메일 또는 비밀번호가 일치하지 않습니다."}"#)
        }
        let isFA = dto.email.lowercased().hasPrefix("fa")
        let token = isFA ? Self.faToken : "mock-access-token"
        let refreshToken = isFA ? "mock-fa-refresh-token" : "mock-refresh-token"
        let roles = isFA ? #"["FA"]"# : #"["Member"]"#
        // 서버(develop)처럼 공통 형식 없이 바로, user.id 는 문자열
        return try respond(request, status: 200, json: """
        {"accessToken":"\(token)","refreshToken":"\(refreshToken)","user":{"id":"1","name":"홍길동","roles":\(roles)}}
        """)
    }

    /// POST /auth/refresh — 서버처럼 공통 형식 없이 새 토큰 한 쌍
    private func refresh(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(RefreshTokenRequestDTO.self, from: body),
            dto.refreshToken != Self.expiredRefreshToken
        else {
            return try respond(request, status: 401, json: #"{"detail":"refresh token이 유효하지 않거나 만료되었습니다."}"#)
        }
        let isFA = dto.refreshToken.contains("fa")
        let token = isFA ? Self.faToken : "mock-access-token"
        return try respond(request, status: 200, json: """
        {"accessToken":"\(token)","refreshToken":"\(dto.refreshToken)"}
        """)
    }

    /// 서버처럼 `{ items, nextCursor }` — 커서는 다음 시작 위치예요.
    private func notifications(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let queryItems = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems ?? []
        let value = { (name: String) in queryItems.first { $0.name == name }?.value.flatMap(Int.init) }
        let all = notificationStore.items()
        let start = min(value("cursor") ?? 0, all.count)
        let end = min(start + (value("limit") ?? 20), all.count)
        let page = MockNotificationPage(items: Array(all[start..<end]), nextCursor: end < all.count ? String(end) : nil)
        let payload = MockEnvelope(code: 200, message: "조회 성공", data: page)
        return try respond(request, status: 200, json: String(decoding: try JSONEncoder().encode(payload), as: UTF8.self))
    }

    /// `{ id }` 하나 또는 `{ all: true }` 전부 — 응답은 `{ updated: n }`
    private func markRead(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        let all = body["all"] as? Bool ?? false
        let id = (body["id"] as? String).flatMap(Int.init)
        guard all || id != nil else {
            return try respond(request, status: 400, json: #"{"detail":"id 또는 all=true를 지정해주세요."}"#)
        }
        let updated = notificationStore.markRead(id: all ? nil : id)
        return try respond(request, status: 200, json: #"{"code":200,"message":"읽음 처리했습니다.","data":{"updated":\#(updated)}}"#)
    }

    /// 05 결재 · 07-4 · 07-5 내 문서 — /approvals/~ (서버 develop 형식)
    private func approvalRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard let url = request.url else { return nil }
        let serverComponents = url.pathComponents.filter { $0 != "/" && $0 != MockTransport.baseURL.lastPathComponent }
        guard serverComponents.first == "approvals" else { return nil }
        return try serverApprovalRoute(request, components: serverComponents)
    }

    /// 08 프로젝트 — /projects/~ (재무 · 내 공간의 projects 와 구분하려고 첫 경로를 확인해요)
    private func projectRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard let url = request.url else { return nil }
        let components = url.pathComponents.filter { $0 != "/" && $0 != MockTransport.baseURL.lastPathComponent }
        if components == ["me"] {
            return try profileRoute(request)
        }
        if components == ["me", "summary"], request.httpMethod == "GET" {
            let todos = todoStore.summary()
            let summary: [String: Any] = [
                "unreadNotifications": notificationStore.items().filter(\.unread).count,
                "submittedApprovals": approvalStore.items(mine: true).count,
                "myPosts": MockActivityFixture.postCount,
                "myProposals": 3,
                "myInquiries": MockActivityFixture.inquiryCount,
                "receivedApprovals": approvalStore.items(mine: false).filter { ["PENDING", "IN_REVIEW"].contains($0.status) }.count,
                "todos": ["total": todos.today.count + todos.completed, "today": todos.today.count,
                          "completed": todos.completed, "linkedApprovals": 0]
            ]
            let data = (try? JSONSerialization.data(withJSONObject: summary, options: [.sortedKeys])) ?? Data()
            return try respond(request, status: 200, json: String(decoding: data, as: UTF8.self))
        }
        if components == ["me", "activity"], request.httpMethod == "GET" {
            return try respond(request, status: 200, json: MockActivityFixture.activity())
        }
        if components == ["me", "projects"], request.httpMethod == "GET" {
            return try respond(request, status: 200, json: MockWorkspaceFixture.projects())
        }
        if components == ["search"], request.httpMethod == "GET" {
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let value = { (name: String) in queryItems.first { $0.name == name }?.value }
            let query = value("query") ?? ""
            guard query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
                return try respond(request, status: 422, json: #"{"code":422,"message":"검색어는 2자 이상 입력해주세요.","data":null}"#)
            }
            return try respond(request, status: 200, json: MockSearchFixture.search(
                query: query,
                offset: value("cursor").flatMap(Int.init) ?? 0,
                limit: value("limit").flatMap(Int.init) ?? 50
            ))
        }
        if components.first == "applications" {
            return try applicationRoute(request, components: components)
        }
        if components.first == "docs" {
            return try docRoute(request, components: components)
        }
        if components.first == "uploads", request.httpMethod == "POST" {
            return try upload(request)
        }
        if components.first == "posts" {
            return try boardRoute(request, components: components)
        }
        if components.first == "notices" {
            return try noticeRoute(request, components: components)
        }
        if components == ["admin", "notices"], request.httpMethod == "POST" {
            return try adminNoticeCreate(request)
        }
        if components.first == "todos" {
            return try todoRoute(request, components: components)
        }
        if components.first == "events" {
            return try eventRoute(request, components: components)
        }
        if components.starts(with: ["admin", "inquiries"]) {
            return try adminInquiryRoute(request, components: Array(components.dropFirst(2)))
        }
        if components.first == "inquiries" {
            return try inquiryRoute(request, components: components)
        }
        if components.first == "proposals" {
            return try proposalRoute(request, components: components)
        }
        guard components.first == "projects" else { return nil }
        let notFound = #"{"detail":"프로젝트를 찾을 수 없습니다."}"#
        let projectId = components.count > 1 ? components[1] : nil
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            return try respond(request, status: 200, json: projectStore.listJSON())
        case ("GET", 2):
            guard let id = projectId, let json = projectStore.detailJSON(id: id) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("GET", 3) where path == "schedule":
            guard let id = projectId, let json = projectStore.timelineJSON(id: id) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("GET", 3) where path == "recruitment":
            guard let id = projectId, let json = projectStore.recruitmentJSON(id: id) else {
                return try respond(request, status: 404, json: #"{"code":404,"message":"모집 중인 자리가 없어요."}"#)
            }
            return try respond(request, status: 200, json: json)
        case ("GET", 3) where path == "applicants":
            guard let id = projectId, let json = projectStore.applicantsJSON(projectId: id) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("POST", 3) where path == "apply":
            guard
                let id = projectId,
                let data = request.httpBody,
                let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            else {
                return try respond(request, status: 400, json: #"{"detail":"잘못된 요청입니다."}"#)
            }
            let result = projectStore.apply(projectId: id, body: body)
            return try respond(request, status: result.0, json: result.1)
        case ("POST", 5) where path == "decision":
            guard
                let id = projectId,
                let applicantId = Int(components[3]),
                let body = request.httpBody,
                let dto = try? JSONCoder.makeDecoder().decode(ApplicantDecisionRequestDTO.self, from: body),
                let json = projectStore.decide(projectId: id, applicantId: applicantId, request: dto)
            else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// 06 문서함 · 09 규칙 — /docs/~ (slug 문자열 id)
    private func docRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let notFound = #"{"detail":"문서를 찾을 수 없습니다."}"#
        let slug = components.count > 1 ? components[1] : ""
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            return try respond(request, status: 200, json: docStore.listJSON(query: Self.query(of: request)))
        case ("GET", 2):
            guard let json = docStore.detailJSON(slug: slug) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("GET", 3) where components[2] == "history":
            guard let json = docStore.historyJSON(slug: slug) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 3) where components[2] == "read":
            guard let json = docStore.read(slug: slug) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// 10 팀 게시판 — /posts(서버 형식 목록) · /posts/{id} · like · reports
    private func boardRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let notFound = #"{"code":404,"message":"해당 게시글을 찾을 수 없습니다."}"#
        let forbidden = #"{"code":403,"message":"이 게시글에는 할 수 없는 작업이에요."}"#
        let id = components.count > 1 ? Int(components[1]) : nil
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            return try respond(request, status: 200, json: boardStore.listJSON(query: Self.query(of: request)))
        case ("GET", 2):
            guard let id = id, let json = boardStore.detailJSON(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("DELETE", 2):
            guard let id = id, boardStore.delete(id: id) else { return try respond(request, status: 403, json: forbidden) }
            return try respond(request, status: 200, json: #"{"code":200,"message":"삭제 완료","data":{"success":true}}"#)
        case ("POST", 1):
            guard let body = request.httpBody, let dto = try? JSONDecoder().decode(ServerPostCreateRequestDTO.self, from: body) else {
                return try respond(request, status: 400, json: #"{"code":400,"message":"잘못된 요청입니다."}"#)
            }
            return try respond(request, status: 201, json: boardStore.create(dto))
        case ("POST", 3) where components[2] == "comments":
            guard
                let id = id,
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(ServerCommentCreateRequestDTO.self, from: body),
                let json = boardStore.createComment(postId: id, request: dto)
            else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 201, json: json)
        case ("POST", 3) where components[2] == "like":
            guard let id = id, let json = boardStore.toggleLike(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 3) where components[2] == "report":
            let reason = request.httpBody.flatMap { try? JSONDecoder().decode(ServerReportRequestDTO.self, from: $0) }?.reason ?? ""
            guard Self.reportReasons.contains(reason) else {
                return try respond(request, status: 422, json: #"{"detail":"신고 사유가 올바르지 않습니다."}"#)
            }
            guard let id = id, boardStore.report(id: id, reason: reason) else { return try respond(request, status: 403, json: forbidden) }
            return try respond(request, status: 201, json: #"{"code":201,"message":"신고 접수 완료","data":{"success":true}}"#)
        default:
            return nil
        }
    }

    /// 10-5 ~ 10-7 공지 — /notices · /notices/{id} · confirm (서버 develop 형식)
    private func noticeRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let store = boardStore.noticeStore
        let notFound = #"{"detail":"리소스를 찾을 수 없습니다."}"#
        let id = components.count > 1 ? Int(components[1]) : nil
        let query = Self.query(of: request)
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1) where query["pinned"] == "true":
            return try respond(request, status: 200, json: boardStore.pinnedNoticesJSON())
        case ("GET", 1):
            let limit = query["limit"].flatMap(Int.init) ?? 20
            guard (1...100).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: store.serverItemsJSON(keyword: query["q"], cursor: query["cursor"], limit: limit))
        case ("GET", 2):
            guard let id = id, let json = store.detailJSON(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 3) where components[2] == "confirm":
            guard let id = id, let json = store.confirm(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// POST /admin/notices — 서버처럼 kind · title · body 가 없으면 400
    private func adminNoticeCreate(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONCoder.makeDecoder().decode(ServerNoticeCreateRequestDTO.self, from: body)
        else { return try respond(request, status: 422, json: #"{"detail":"잘못된 요청입니다."}"#) }
        for (field, value) in [("kind", dto.kind), ("title", dto.title), ("body", dto.body)] where value.isEmpty {
            return try respond(request, status: 400, json: #"{"detail":"\#(field) 항목은 필수입니다."}"#)
        }
        return try respond(request, status: 201, json: boardStore.noticeStore.publish(dto))
    }

    /// 11 문의 — GET · POST /inquiries (서버 develop 형식)
    private func inquiryRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            let query = Self.query(of: request)
            let limit = query["limit"].flatMap(Int.init) ?? 20
            guard (1...100).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: inquiryStore.mineJSON(cursor: query["cursor"], limit: limit))
        case ("POST", 1):
            let types: Set<String> = ["문의", "건의", "불편 신고"]
            guard
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(ServerInquiryCreateRequestDTO.self, from: body),
                types.contains(dto.type), !dto.dept.isEmpty, !dto.title.isEmpty, !dto.body.isEmpty
            else { return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#) }
            return try respond(request, status: 201, json: inquiryStore.submit(dto))
        default:
            return nil
        }
    }

    /// 05 결재 — GET /approvals?box= · GET /approvals/{id} · POST approve · reject · cancel · comments
    private func serverApprovalRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let notFound = #"{"detail":"결재를 찾을 수 없습니다."}"#
        switch (request.httpMethod ?? "", components.count) {
        case ("POST", 1):
            let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            switch approvalStore.create(body) {
            case .success(let json): return try respond(request, status: 201, json: json)
            case .failure(.invalid(let message)): return try respond(request, status: 422, json: #"{"detail":"\#(message)"}"#)
            }
        case ("GET", 1):
            let query = Self.query(of: request)
            let box = query["box"] ?? "mine"
            guard ["mine", "received", "handled"].contains(box) else {
                return try respond(request, status: 400, json: #"{"detail":"box는 mine, received, handled 중 하나여야 합니다."}"#)
            }
            let limit = query["limit"].flatMap(Int.init) ?? 20
            return try respond(request, status: 200, json: approvalStore.serverListJSON(box: box, cursor: query["cursor"], limit: limit))
        case ("GET", 2):
            guard let id = Int(components[1]), let json = approvalStore.serverDetailJSON(id: id) else {
                return try respond(request, status: 404, json: notFound)
            }
            return try respond(request, status: 200, json: json)
        case ("POST", 3):
            guard let id = Int(components[1]) else { return try respond(request, status: 404, json: notFound) }
            let body = request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
            switch components[2] {
            case "approve", "reject":
                switch approvalStore.decide(id: id, approve: components[2] == "approve", reason: body["reason"] as? String) {
                case .success(let json): return try respond(request, status: 200, json: json)
                case .failure(.notFound): return try respond(request, status: 404, json: notFound)
                case .failure(.notMyTurn): return try respond(request, status: 403, json: #"{"detail":"현재 결재 차례가 아닙니다."}"#)
                case .failure(.invalidState): return try respond(request, status: 409, json: #"{"detail":"처리할 수 있는 결재 상태가 아닙니다."}"#)
                case .failure(.missingReason): return try respond(request, status: 400, json: #"{"detail":"반려 사유를 입력해주세요."}"#)
                }
            case "cancel":
                guard let json = approvalStore.cancel(id: id) else {
                    return try respond(request, status: 403, json: #"{"detail":"취소할 수 없는 결재입니다."}"#)
                }
                return try respond(request, status: 200, json: json)
            case "comments":
                let text = (body["text"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return try respond(request, status: 400, json: #"{"detail":"댓글 내용을 입력해주세요."}"#) }
                guard let json = approvalStore.serverComment(id: id, text: text) else {
                    return try respond(request, status: 404, json: notFound)
                }
                return try respond(request, status: 201, json: json)
            default:
                return nil
            }
        default:
            return nil
        }
    }

    /// 07-13 내 프로필 — GET · PATCH /me (서버 develop 형식)
    private func profileRoute(_ request: URLRequest) throws -> (Data, HTTPURLResponse)? {
        switch request.httpMethod ?? "" {
        case "GET":
            return try respond(request, status: 200, json: profileStore.json())
        case "PATCH":
            guard let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerProfilePatchRequestDTO.self, from: body)
            else { return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#) }
            guard dto.interests.count <= 5 else {
                return try respond(request, status: 422, json: #"{"detail":"관심사는 최대 5개까지 등록할 수 있습니다."}"#)
            }
            guard dto.bio.count <= 60 else {
                return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#)
            }
            return try respond(request, status: 200, json: profileStore.update(dto))
        default:
            return nil
        }
    }

    /// 07-7 · 07-8 일정 — GET /events?month= · POST /events/{id}/rsvp (서버 develop 형식)
    private func eventRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            let query = Self.query(of: request)
            let limit = query["limit"].flatMap(Int.init) ?? 100
            guard (1...200).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: scheduleStore.listJSON(month: query["month"], cursor: query["cursor"], limit: limit))
        case ("POST", 3) where components[2] == "rsvp":
            guard let id = Int(components[1]), let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerRsvpRequestDTO.self, from: body),
                  ["참석", "불참", "미정"].contains(dto.rsvp)
            else { return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#) }
            guard let json = scheduleStore.rsvp(id: id, value: dto.rsvp) else {
                return try respond(request, status: 404, json: #"{"detail":"일정을 찾을 수 없습니다."}"#)
            }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// 07-2 할 일 — GET · POST /todos · PATCH /todos/{id} (서버 develop 형식)
    private func todoRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            let query = Self.query(of: request)
            let limit = query["limit"].flatMap(Int.init) ?? 30
            guard (1...100).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: todoStore.listJSON(cursor: query["cursor"], limit: limit))
        case ("POST", 1):
            guard let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerTodoCreateRequestDTO.self, from: body), !dto.title.isEmpty
            else { return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#) }
            return try respond(request, status: 201, json: todoStore.add(dto))
        case ("PATCH", 2):
            guard let id = Int(components[1]), let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerTodoPatchRequestDTO.self, from: body),
                  ["미완료", "예정", "완료"].contains(dto.status)
            else { return try respond(request, status: 404, json: #"{"detail":"리소스를 찾을 수 없습니다."}"#) }
            guard let json = todoStore.update(id: id, status: dto.status) else {
                return try respond(request, status: 404, json: #"{"detail":"할 일을 찾을 수 없습니다."}"#)
            }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// 11-5 · 11-6 담당자 — GET /admin/inquiries · PATCH /admin/inquiries/{id} · POST /admin/inquiries/{id}/answer
    private func adminInquiryRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let notFound = #"{"detail":"리소스를 찾을 수 없습니다."}"#
        let id = components.first.flatMap(Int.init)
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 0):
            let query = Self.query(of: request)
            let limit = query["limit"].flatMap(Int.init) ?? 30
            guard (1...100).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: inquiryStore.adminJSON(status: query["status"], cursor: query["cursor"], limit: limit))
        case ("PATCH", 1):
            // 서버 허용 상태 + 반려(백엔드 협의안)
            let states: Set<String> = ["접수", "검토 중", "답변 완료", "해결됨", "반려"]
            guard let id, let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerInquiryPatchRequestDTO.self, from: body), states.contains(dto.status)
            else { return try respond(request, status: 422, json: #"{"detail":"문의 상태가 올바르지 않습니다."}"#) }
            guard let json = inquiryStore.patch(id: id, request: dto) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 2) where components[1] == "answer":
            guard let id, let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerInquiryAnswerRequestDTO.self, from: body),
                  !dto.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return try respond(request, status: 400, json: #"{"detail":"답변을 입력해주세요."}"#) }
            guard let json = inquiryStore.answer(id: id, request: dto) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        default:
            return nil
        }
    }

    /// 12 운영 제안 — /proposals · /proposals/{id} · recommend · comments (서버 develop 형식)
    private func proposalRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        let notFound = #"{"detail":"리소스를 찾을 수 없습니다."}"#
        let id = components.count > 1 ? Int(components[1]) : nil
        let query = Self.query(of: request)
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 1):
            let limit = query["limit"].flatMap(Int.init) ?? 20
            guard (1...100).contains(limit) else { return try respond(request, status: 422, json: #"{"detail":"limit 범위가 아니에요."}"#) }
            return try respond(request, status: 200, json: proposalStore.listJSON(cursor: query["cursor"], limit: limit))
        case ("GET", 2):
            guard let id = id, let json = proposalStore.detailJSON(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 1):
            guard
                let body = request.httpBody,
                let dto = try? JSONDecoder().decode(ServerProposalCreateRequestDTO.self, from: body)
            else { return try respond(request, status: 422, json: #"{"detail":"잘못된 요청입니다."}"#) }
            guard !dto.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return try respond(request, status: 422, json: #"{"detail":"제안 내용을 입력해주세요."}"#)
            }
            return try respond(request, status: 201, json: proposalStore.create(dto))
        case ("POST", 3) where components[2] == "recommend":
            guard let id = id, let json = proposalStore.toggleRecommend(id: id) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 200, json: json)
        case ("POST", 3) where components[2] == "comments":
            guard let id = id, let body = request.httpBody,
                  let dto = try? JSONDecoder().decode(ServerProposalCommentRequestDTO.self, from: body)
            else { return try respond(request, status: 404, json: notFound) }
            guard !dto.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return try respond(request, status: 422, json: #"{"detail":"댓글 내용을 입력해주세요."}"#)
            }
            guard let json = proposalStore.addComment(id: id, request: dto) else { return try respond(request, status: 404, json: notFound) }
            return try respond(request, status: 201, json: json)
        default:
            return nil
        }
    }

    /// 08-6 내 참여 신청 — GET /applications/mine · DELETE /applications/{id}
    private func applicationRoute(_ request: URLRequest, components: [String]) throws -> (Data, HTTPURLResponse)? {
        switch (request.httpMethod ?? "", components.count) {
        case ("GET", 2) where components[1] == "mine":
            return try respond(request, status: 200, json: projectStore.myApplicationsJSON())
        case ("DELETE", 2):
            guard let id = Int(components[1]), projectStore.cancelApplication(id: id) else {
                return try respond(request, status: 409, json: #"{"code":409,"message":"취소할 수 없는 신청이에요."}"#)
            }
            return try respond(request, status: 200, json: #"{"code":200,"message":"취소 완료","data":{"success":true}}"#)
        default:
            return nil
        }
    }

    /// 04 재무 — GET /finance/summary · /finance/receipts · /finance/contracts/{project} (FA 토큰이 아니면 403)
    private func financeRoute(_ request: URLRequest, path: String) throws -> (Data, HTTPURLResponse)? {
        guard request.httpMethod == "GET", let url = request.url else { return nil }
        let components = Array(url.pathComponents.drop(while: { $0 != "finance" }))
        guard components.first == "finance", components.count >= 2 else { return nil }
        guard request.value(forHTTPHeaderField: "Authorization")?.contains(Self.faToken) == true else {
            return try respond(request, status: 403, json: MockFinanceFixture.forbidden)
        }
        switch (components[1], components.count) {
        case ("summary", 2):
            return try respond(request, status: 200, json: MockFinanceFixture.summary())
        case ("receipts", 2):
            return try respond(request, status: 200, json: MockFinanceFixture.receipts(query: Self.query(of: request)))
        case ("contracts", 3):
            guard let json = MockFinanceFixture.contract(project: components[2]) else {
                return try respond(request, status: 404, json: #"{"detail":"계약 정보를 찾을 수 없습니다."}"#)
            }
            return try respond(request, status: 200, json: json)
        default:
            return nil
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

    /// GET /users/me — 서버처럼 공통 형식 없이 바로
    private func me(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let authorization = request.value(forHTTPHeaderField: "Authorization")
        guard let authorization, !authorization.contains(Self.expiredAccessToken) else {
            return try respond(request, status: 401, json: Self.unauthorizedDetail)
        }
        let isFA = authorization.contains(Self.faToken)
        let department = isFA ? "FA" : "NativeOps"
        let roles = isFA ? #"["FA"]"# : #"["Member","PM"]"#
        return try respond(request, status: 200, json: """
        {"id":1,"name":"홍길동","email":"s00000@gsm.hs.kr","department":"\(department)","roles":\(roles)}
        """)
    }

    /// `POST /auth/signup-requests` — `taken@` 으로 시작하면 이미 있는 이메일
    private func accountRequest(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        guard
            let body = request.httpBody,
            let dto = try? JSONDecoder().decode(AccountRequestRequestDTO.self, from: body)
        else {
            return try respond(request, status: 422, json: #"{"detail":"입력한 정보를 다시 확인해 주세요."}"#)
        }
        if dto.email.hasPrefix("taken@") {
            return try respond(request, status: 409, json: #"{"detail":"이미 등록된 이메일입니다."}"#)
        }
        return try respond(request, status: 202, json: #"{"id":"12","status":"PENDING"}"#)
    }

    /// 서버 `REPORT_REASONS`
    static let reportReasons: Set<String> = ["욕설·비하", "개인정보 노출", "도배·광고", "사실과 다른 내용", "기타"]

    /// POST /uploads — multipart 로 온 JPG · PNG 만 받아요.
    private func upload(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard contentType.hasPrefix("multipart/form-data"), let body = request.httpBody, !body.isEmpty else {
            return try respond(request, status: 422, json: #"{"detail":"파일이 필요합니다."}"#)
        }
        let id = UUID().uuidString.prefix(8).lowercased()
        return try respond(request, status: 201, json: #"{"id":"\#(id)","url":"/uploads/\#(id)","filename":"image","size":\#(body.count)}"#)
    }

    /// 요청 URL 의 쿼리를 이름 → 값으로
    static func query(of request: URLRequest) -> [String: String] {
        let items = request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems ?? []
        return Dictionary(items.compactMap { item in item.value.map { (item.name, $0) } }, uniquingKeysWith: { _, last in last })
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

private struct MockNotificationPage: Encodable {
    let items: [MockNotificationStore.Item]
    let nextCursor: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(nextCursor, forKey: .nextCursor)
    }

    private enum CodingKeys: String, CodingKey {
        case items
        case nextCursor
    }
}

/// Mock 알림 — Figma 02-2 · 02-3 · 02-4 알림 센터 예시를 서버 develop 형식으로
/// `{ id: "101", kind, sourceKind, title, createdAt, href, unread, action }` (본문 · 시행일은 서버에 없어요)
private final class MockNotificationStore: @unchecked Sendable {
    struct Item: Encodable {
        let id: String
        let kind: String
        let sourceKind: String
        let title: String
        let createdAt: String
        let href: String
        var unread: Bool
        var action = false
    }

    private let lock = NSLock()
    private var storage: [Item]

    init(now: Date = Date()) {
        let formatter = ISO8601DateFormatter()
        func ago(_ seconds: TimeInterval) -> String { formatter.string(from: now.addingTimeInterval(-seconds)) }
        func item(_ id: Int, _ kind: String, _ title: String, _ href: String, unread: Bool, _ seconds: TimeInterval, action: Bool = false) -> Item {
            Item(id: String(id), kind: kind, sourceKind: kind, title: title, createdAt: ago(seconds), href: href, unread: unread, action: action)
        }
        storage = [
            item(101, "내 업무", "이시우님이 'Book-on 인력 지원' 결재를 요청했어요", "/inhouse/requests/12", unread: true, 30, action: true),
            item(102, "재정", "BRIDGE iOS 앱 프로토타입 3,600,000원이 입금됐어요", "/inhouse/finance/receipts", unread: true, 32 * 60),
            item(103, "일정", "디자인 리뷰 시간이 10.14 (화) 15:00로 바뀌었어요", "/inhouse/my/calendar", unread: true, 2 * 3_600),
            item(107, "내 업무", "문의에 답변이 등록됐어요.", "/inhouse/community/inquiry?id=42", unread: true, 3 * 3_600),
            item(104, "공지", "'프로젝트 운영 원칙'이 개정됐어요", "/inhouse/documents/project-principles", unread: true, 86_400),
            item(108, "공지", "프로젝트 문서 분류 안내", "/inhouse/documents", unread: false, 6 * 86_400),
            item(105, "공지", "10월 정기 회의 장소 안내", "/inhouse/community/notices/1", unread: false, 4 * 86_400),
            item(106, "내 업무", "'Book-on 테스트 기기 구매' 결재가 승인됐어요", "/inhouse/requests/55", unread: false, 5 * 86_400)
        ]
    }

    func items() -> [Item] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    /// id 가 nil 이면 전부 — 바뀐 개수를 돌려줘요.
    func markRead(id: Int?) -> Int {
        lock.lock()
        defer { lock.unlock() }
        var updated = 0
        for index in storage.indices where id == nil || storage[index].id == id.map(String.init) {
            storage[index].unread = false
            updated += 1
        }
        return updated
    }
}
