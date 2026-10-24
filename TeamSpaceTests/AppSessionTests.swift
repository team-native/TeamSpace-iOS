import XCTest
@testable import TeamSpace

@MainActor
final class AppSessionTests: XCTestCase {
    private let tokenStorage = InMemoryTokenStorage()

    private func makeContainer() -> DIContainer {
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testWithoutTokenGoesToLogin() async {
        let session = makeContainer().makeAppSession()

        await session.restore()

        XCTAssertEqual(session.state, .signedOut)
    }

    func testWithSavedTokenSignsInAutomatically() async throws {
        try tokenStorage.save(AuthToken(accessToken: "saved", refreshToken: "saved"), persistent: true)
        let session = makeContainer().makeAppSession()

        await session.restore()

        XCTAssertEqual(session.currentUser?.name, "홍길동")
        XCTAssertEqual(session.currentUser?.roles, [.member, .pm])
    }

    func testLogoutClearsToken() async throws {
        try tokenStorage.save(AuthToken(accessToken: "saved", refreshToken: "saved"), persistent: true)
        let session = makeContainer().makeAppSession()
        await session.restore()

        session.signOut()

        XCTAssertEqual(session.state, .signedOut)
        XCTAssertNil(tokenStorage.load())
    }

    func testUserMeResponseFromSpecExample() throws {
        let json = #"""
        {"code":200,"message":"조회 성공","data":{"id":1,"name":"홍길동","email":"s00000@gsm.hs.kr",
         "department":"NativeOps","roles":["Member","PM"]}}
        """#
        let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<UserMeResponseDTO>.self, from: Data(json.utf8))
        let dto = try XCTUnwrap(envelope.data)
        XCTAssertEqual(dto.department, .nativeOps)
        XCTAssertEqual(dto.toEntity(), AuthUser(id: 1, name: "홍길동", roles: [.member, .pm]))
    }
}
