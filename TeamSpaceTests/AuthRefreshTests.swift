import XCTest
@testable import TeamSpace

/// 백엔드 API 맞추기 1 — 로그인 · 토큰 갱신 (TeamSpace-backend develop `app/api/auth.py`)
@MainActor
final class AuthRefreshTests: XCTestCase {
    private let tokenStorage = InMemoryTokenStorage()

    private func makeContainer() -> (DIContainer, APIClient) {
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return (DIContainer(apiClient: client, tokenStorage: tokenStorage), client)
    }

    // MARK: 공통 형식 없이 내려오는 응답

    func testLoginReadsServerShapeWithStringUserId() async throws {
        let login = LoginUseCase(authRepository: AuthRepositoryImpl(client: makeContainer().1), tokenStorage: tokenStorage)

        let user = try await login.execute(LoginCredential(email: "member@gsm.hs.kr", password: "pw", keepSignedIn: false))

        XCTAssertEqual(user.id, 1, "서버는 user.id 를 문자열 \"1\" 로 보내요")
        XCTAssertEqual(tokenStorage.load()?.refreshToken, "mock-refresh-token")
        XCTAssertEqual(tokenStorage.lastSavedAsPersistent, false)
    }

    func testDecodePayloadAcceptsEnvelopeAndRawBody() throws {
        let raw = Data(#"{"accessToken":"a","refreshToken":"r"}"#.utf8)
        let wrapped = Data(#"{"code":200,"message":"OK","data":{"accessToken":"a","refreshToken":"r"}}"#.utf8)

        XCTAssertEqual(try APIClient.decodePayload(RefreshTokenResponseDTO.self, from: raw).accessToken, "a")
        XCTAssertEqual(try APIClient.decodePayload(RefreshTokenResponseDTO.self, from: wrapped).refreshToken, "r")
    }

    func testFastAPIErrorDetailBecomesUserMessage() throws {
        let body = try JSONCoder.makeDecoder().decode(
            APIErrorResponseDTO.self,
            from: Data(#"{"detail":"검색어는 2자 이상 입력해주세요."}"#.utf8)
        )
        XCTAssertEqual(body.message, "검색어는 2자 이상 입력해주세요.")
        guard case .invalidInput(let message) = NetworkError.status(code: 422, body: body).asAppError else {
            return XCTFail("422 는 입력 오류예요")
        }
        XCTAssertEqual(message, "검색어는 2자 이상 입력해주세요.")

        let validation = try JSONCoder.makeDecoder().decode(
            APIErrorResponseDTO.self,
            from: Data(#"{"detail":[{"loc":["body","email"],"msg":"value is not a valid email address","type":"value_error"}]}"#.utf8)
        )
        guard case .invalidInput(let fallback) = NetworkError.status(code: 422, body: validation).asAppError else {
            return XCTFail("422 는 입력 오류예요")
        }
        XCTAssertEqual(fallback, "입력한 정보를 다시 확인해 주세요.", "영문 검증 메시지는 그대로 보여주지 않아요")
    }

    // MARK: 토큰 갱신

    func testExpiredAccessTokenRefreshesAndRetries() async throws {
        try tokenStorage.save(AuthToken(accessToken: MockTransport.expiredAccessToken, refreshToken: "mock-refresh-token"), persistent: true)
        let session = makeContainer().0.makeAppSession()

        await session.restore()

        XCTAssertEqual(session.currentUser?.name, "홍길동", "갱신 후 같은 요청을 다시 보내요")
        XCTAssertEqual(tokenStorage.load()?.accessToken, "mock-access-token")
        XCTAssertEqual(tokenStorage.lastSavedAsPersistent, true, "로그인 상태 유지 설정은 그대로")
    }

    func testExpiredRefreshTokenClearsTokens() async throws {
        try tokenStorage.save(
            AuthToken(accessToken: MockTransport.expiredAccessToken, refreshToken: MockTransport.expiredRefreshToken),
            persistent: true
        )

        do {
            _ = try await AuthRepositoryImpl(client: makeContainer().1).fetchMe()
            XCTFail("리프레시 토큰도 만료면 실패해요")
        } catch AppError.unauthorized {
            XCTAssertNil(tokenStorage.load(), "토큰을 지워요")
        }
    }

    func testSessionExpiryHandlerSignsOutWithNotice() async throws {
        let (container, client) = makeContainer()
        let session = container.makeAppSession()
        session.signIn(AuthUser(id: 1, name: "홍길동", roles: [.member]))
        try tokenStorage.save(
            AuthToken(accessToken: MockTransport.expiredAccessToken, refreshToken: MockTransport.expiredRefreshToken),
            persistent: true
        )

        _ = try? await AuthRepositoryImpl(client: client).fetchMe()
        for _ in 0..<20 where session.state != .signedOut { await Task.yield() }

        XCTAssertEqual(session.state, .signedOut)
        XCTAssertTrue(session.isExpiredNoticePresented)
    }

    func testConcurrentUnauthorizedRequestsRefreshOnce() async throws {
        let transport = CountingRefreshTransport()
        try tokenStorage.save(AuthToken(accessToken: "old", refreshToken: "refresh"), persistent: false)
        let client = APIClient(baseURL: MockTransport.baseURL, transport: transport, tokenStorage: tokenStorage)
        let repository = AuthRepositoryImpl(client: client)

        async let first = repository.fetchMe()
        async let second = repository.fetchMe()
        async let third = repository.fetchMe()
        let users = try await [first, second, third]

        XCTAssertEqual(users.map(\.id), [7, 7, 7])
        let refreshCount = await transport.refreshCount
        XCTAssertEqual(refreshCount, 1, "갱신 요청은 한 번만")
        XCTAssertEqual(tokenStorage.load()?.accessToken, "new")
    }
}

/// "old" 토큰이면 401, `/auth/refresh` 는 잠깐 기다렸다가 "new" 를 줘요 — 갱신 횟수를 셉니다.
private actor CountingRefreshTransport: HTTPTransport {
    private(set) var refreshCount = 0

    nonisolated func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await handle(request)
    }

    private func handle(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else { throw URLError(.badURL) }
        if url.lastPathComponent == "refresh" {
            refreshCount += 1
            try await Task.sleep(nanoseconds: 50_000_000)
            return response(url, 200, #"{"accessToken":"new","refreshToken":"refresh-2"}"#)
        }
        if request.value(forHTTPHeaderField: "Authorization") == "Bearer new" {
            return response(url, 200, #"{"id":7,"name":"테스트","email":"t@gsm.hs.kr","department":null,"roles":["Member"]}"#)
        }
        return response(url, 401, #"{"detail":"유효하지 않거나 만료된 토큰입니다. 로그인해 주세요."}"#)
    }

    private func response(_ url: URL, _ status: Int, _ json: String) -> (Data, HTTPURLResponse) {
        (Data(json.utf8), HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) ?? HTTPURLResponse())
    }
}
