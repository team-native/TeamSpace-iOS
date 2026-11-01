import XCTest
@testable import TeamSpace

/// 백엔드 API 맞추기 2 — 계정 요청 · 비밀번호 재설정 (TeamSpace-backend develop `app/api/account.py`)
final class AccountAPITests: XCTestCase {
    private func makeRepository(_ transport: RecordingTransport) -> AuthRepositoryImpl {
        AuthRepositoryImpl(client: APIClient(
            baseURL: MockTransport.baseURL,
            transport: transport,
            tokenStorage: InMemoryTokenStorage()
        ))
    }

    private var form: AccountRequestForm {
        AccountRequestForm(name: "옥물결", email: "s26043@gsm.hs.kr", department: .design, password: "abcd1234")
    }

    func testAccountRequestUsesSignupRequestsWithDept() async throws {
        let transport = RecordingTransport(status: 202, json: #"{"id":"12","status":"PENDING"}"#)

        let receipt = try await makeRepository(transport).requestAccount(form)

        let request = await transport.lastRequest
        XCTAssertEqual(request?.url?.lastPathComponent, "signup-requests")
        XCTAssertEqual(request?.url?.deletingLastPathComponent().lastPathComponent, "auth")
        XCTAssertEqual(request?.httpMethod, "POST")
        let body = try XCTUnwrap(request?.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: String] })
        XCTAssertEqual(body, ["email": "s26043@gsm.hs.kr", "name": "옥물결", "dept": "Design", "password": "abcd1234"])
        XCTAssertEqual(receipt.status, .reviewing, "PENDING 은 검토 중")
        XCTAssertEqual(receipt.name, "옥물결")
        XCTAssertEqual(receipt.department, .design)
    }

    func testOptionalFieldsAreSentOnlyWhenFilled() async throws {
        let transport = RecordingTransport(status: 202, json: #"{"id":"13","status":"PENDING"}"#)
        let useCase = RequestAccountUseCase(authRepository: makeRepository(transport))
        var filled = form
        filled.major = " 스마트IoT과 "
        filled.cohort = "9기"
        filled.message = "  "

        _ = try await useCase.execute(filled)

        let request = await transport.lastRequest
        let body = try XCTUnwrap(request?.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: String] })
        XCTAssertEqual(body["major"], "스마트IoT과", "앞뒤 공백은 지워요")
        XCTAssertEqual(body["cohort"], "9기")
        XCTAssertNil(body["message"], "비어 있으면 보내지 않아요")
    }

    func testDuplicateEmailIsConflict() async {
        let transport = RecordingTransport(status: 409, json: #"{"detail":"이미 검토 중인 가입 요청이 있습니다."}"#)

        do {
            _ = try await makeRepository(transport).requestAccount(form)
            XCTFail("409 는 실패해요")
        } catch AppError.conflict(let message) {
            XCTAssertEqual(message, "이미 검토 중인 가입 요청이 있습니다.")
        } catch {
            XCTFail("예상과 다른 오류: \(error)")
        }
    }

    func testPasswordResetUsesResetRequestsPath() async throws {
        let transport = RecordingTransport(status: 202, json: #"{"accepted":true}"#)

        try await makeRepository(transport).requestPasswordReset(email: "s26043@gsm.hs.kr")

        let request = await transport.lastRequest
        XCTAssertEqual(request?.url?.lastPathComponent, "password-reset-requests")
        XCTAssertEqual(request?.url?.deletingLastPathComponent().lastPathComponent, "auth")
    }

    func testStatusMapping() {
        XCTAssertEqual(AccountRequestStatus(serverValue: "PENDING"), .reviewing)
        XCTAssertEqual(AccountRequestStatus(serverValue: "approved"), .approved)
        XCTAssertEqual(AccountRequestStatus(serverValue: "WHATEVER"), .unknown)
    }
}

/// 받은 요청을 기억하고 정해진 응답을 돌려줘요.
private actor RecordingTransport: HTTPTransport {
    private let status: Int
    private let json: String
    private(set) var lastRequest: URLRequest?

    init(status: Int, json: String) {
        self.status = status
        self.json = json
    }

    nonisolated func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await record(request)
    }

    private func record(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        lastRequest = request
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw URLError(.badURL)
        }
        return (Data(json.utf8), response)
    }
}
