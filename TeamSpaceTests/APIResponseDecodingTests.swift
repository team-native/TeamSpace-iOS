import XCTest
@testable import TeamSpace

/// API 명세서(Notion) 응답 형식 디코딩 확인
final class APIResponseDecodingTests: XCTestCase {
    func testNestedLoginResponseFromSpecExample() throws {
        let json = #"""
        {"code":200,"message":"로그인 성공","data":{"accessToken":"a","refreshToken":"r",
         "user":{"id":1,"name":"홍길동","roles":["Member"]}}}
        """#
        let envelope = try JSONCoder.makeDecoder().decode(APIResponseDTO<LoginResponseDTO>.self, from: Data(json.utf8))
        let session = try XCTUnwrap(envelope.data).toEntity()
        XCTAssertEqual(session.user, AuthUser(id: 1, name: "홍길동", roles: [.member]))
        XCTAssertEqual(session.token.accessToken, "a")
    }

    func testFlatLoginResponseFromSpecTable() throws {
        let json = #"""
        {"accessToken":"a","refreshToken":"r","userId":1,"userName":"홍길동","userRoles":["PM","SUPER_NEW_ROLE"]}
        """#
        let dto = try JSONCoder.makeDecoder().decode(LoginResponseDTO.self, from: Data(json.utf8))
        XCTAssertEqual(dto.toEntity().user.roles, [.pm, .unknown], "모르는 역할은 .unknown")
    }

    func testBadRequestUsesFieldReason() throws {
        let json = #"""
        {"code":400,"message":"잘못된 요청 파라미터입니다.","errors":[{"field":"email","reason":"이메일 형식이 올바르지 않습니다."}]}
        """#
        let body = try JSONCoder.makeDecoder().decode(APIErrorResponseDTO.self, from: Data(json.utf8))
        XCTAssertEqual(NetworkError.status(code: 400, body: body).asAppError, .invalidInput("이메일 형식이 올바르지 않습니다."))
    }

    func testStatusMapping() {
        XCTAssertEqual(NetworkError.status(code: 403, body: nil).asAppError, .forbidden(nil))
        XCTAssertEqual(NetworkError.status(code: 500, body: nil).asAppError, .server(statusCode: 500))
    }
}
