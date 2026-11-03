import XCTest
@testable import TeamSpace

/// 규칙 문서 등록 · 개정 (POST /admin/docs)
@MainActor
final class RuleComposeTests: XCTestCase {
    private let admin = AuthUser(id: 3, name: "관리자", roles: [.admin])
    private let leader = AuthUser(id: 2, name: "이시우", roles: [.pm, .leader])

    private func makeContainer() -> DIContainer {
        let tokenStorage = InMemoryTokenStorage()
        let client = APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: tokenStorage
        )
        return DIContainer(apiClient: client, tokenStorage: tokenStorage)
    }

    func testAdminRegistersRule() async throws {
        let container = makeContainer()
        let compose = container.makeRuleComposeViewModel(user: admin)
        XCTAssertEqual(compose.screenTitle, "규칙 등록")
        XCTAssertFalse(compose.canSubmit, "제목 · 조항이 없으면 못 보내요")

        compose.draft.title = "  재택 근무 규칙  "
        compose.draft.summary = "재택 근무 신청과 기록 방법"
        compose.draft.category = .people
        compose.draft.articles[0].title = "목적"
        compose.draft.articles[0].body = "재택 근무 기준을 정해요."
        compose.addArticle()
        compose.draft.articles[1].title = "신청"
        compose.draft.articles[1].body = "전날까지 일정에 올려요.\n리더가 확인해요."
        XCTAssertTrue(compose.canSubmit)
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertTrue(compose.didSave)
        let slug = try XCTUnwrap(compose.savedSlug)
        XCTAssertTrue(slug.hasPrefix("rule-"))

        let list = container.makeRuleListViewModel()
        await list.load()
        let summary = try XCTUnwrap(list.rules.first { $0.id == slug }, "규칙 · 제도 목록에 올라가요")
        XCTAssertEqual(summary.title, "재택 근무 규칙")
        XCTAssertEqual(summary.category, .people)
        XCTAssertEqual(summary.version, "v1.0")

        let detail = container.makeRuleDetailViewModel(ruleId: slug)
        await detail.load()
        let rule = try XCTUnwrap(detail.detail)
        XCTAssertEqual(rule.articles.map(\.number), [1, 2])
        XCTAssertEqual(rule.articles.map(\.title), ["목적", "신청"])
        XCTAssertEqual(rule.articles[1].body, "전날까지 일정에 올려요.\n리더가 확인해요.")
        XCTAssertEqual(rule.summaryText, "재택 근무 신청과 기록 방법")
        XCTAssertEqual(rule.revisions.first?.summary, "최초 등록")
    }

    func testAdminRevisesRuleBumpsVersion() async throws {
        let container = makeContainer()
        let before = container.makeRuleDetailViewModel(ruleId: "meeting-principles")
        await before.load()
        let original = try XCTUnwrap(before.detail)
        XCTAssertEqual(original.rule.version, "v1.1")

        let compose = container.makeRuleComposeViewModel(user: admin, editing: original)
        XCTAssertTrue(compose.isRevision)
        XCTAssertEqual(compose.screenTitle, "규칙 개정")
        XCTAssertEqual(compose.draft.articles.count, original.articles.count)
        XCTAssertEqual(compose.changedCountText, "아직 바뀐 조항이 없어요")
        XCTAssertFalse(compose.canSubmit, "개정 사유가 있어야 해요")

        compose.draft.articles[1].body = "Native 모든 구성원에게 적용돼요."
        compose.draft.note = "제2조 적용 범위 정리"
        XCTAssertEqual(compose.changedCountText, "바뀐 조항 1개")
        await compose.submit()
        XCTAssertNil(compose.errorMessage)
        XCTAssertEqual(compose.savedSlug, "meeting-principles")
        XCTAssertEqual(compose.completionTitle, "규칙을 개정했어요")

        let after = container.makeRuleDetailViewModel(ruleId: "meeting-principles")
        await after.load()
        let updated = try XCTUnwrap(after.detail)
        XCTAssertEqual(updated.rule.version, "v1.2")
        XCTAssertEqual(updated.categoryText, original.categoryText, "분류를 그대로 두면 원래 글자")
        XCTAssertEqual(updated.articles[1].body, "Native 모든 구성원에게 적용돼요.")
        XCTAssertEqual(updated.articles.map(\.isRevised), [false, true, false], "바뀐 조항만 개정 표시")
        XCTAssertEqual(updated.revisions.first?.version, "v1.2")
        XCTAssertEqual(updated.revisions.first?.summary, "제2조 적용 범위 정리")
        XCTAssertEqual(updated.revisions.count, 3, "이전 내역은 그대로")
    }

    func testValidation() async throws {
        let container = makeContainer()
        let useCase = SaveRuleUseCase(ruleRepository: RuleRepositoryImpl(client: APIClient(
            baseURL: MockTransport.baseURL,
            transport: MockTransport(latencyNanoseconds: 0),
            tokenStorage: InMemoryTokenStorage()
        )))
        var draft = RuleDraft()
        draft.title = "보안 규칙"
        draft.articles[0].title = "목적"
        await assertInvalid(useCase, draft, "조항마다 제목과 내용을 써 주세요.")

        draft.articles[0].title = ""
        draft.articles[0].body = ""
        await assertInvalid(useCase, draft, "조항을 하나 이상 써 주세요.")

        draft.title = String(repeating: "가", count: 61)
        draft.articles[0] = RuleDraft.Article(title: "목적", body: "내용")
        await assertInvalid(useCase, draft, "제목은 1~60자로 써 주세요.")

        let detail = container.makeRuleDetailViewModel(ruleId: "onboarding")
        await detail.load()
        var revision = RuleDraft(editing: try XCTUnwrap(detail.detail))
        revision.note = "   "
        await assertInvalid(useCase, revision, "개정 사유를 1~100자로 써 주세요.")
    }

    func testNonAdminIsForbidden() async throws {
        let container = makeContainer()
        let compose = container.makeRuleComposeViewModel(user: leader)
        compose.draft.title = "규칙"
        compose.draft.articles[0].title = "목적"
        compose.draft.articles[0].body = "내용"
        await compose.submit()
        XCTAssertFalse(compose.didSave)
        XCTAssertEqual(compose.errorMessage, "규칙은 관리자만 등록할 수 있어요.")
        XCTAssertFalse(leader.can(.manageDocs))
        XCTAssertTrue(admin.can(.manageDocs))
    }

    func testWriteRequestShape() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        var draft = RuleDraft(now: Date(timeIntervalSince1970: 0), calendar: calendar)
        draft.title = "회의 규칙"
        draft.category = .finance
        draft.effectiveDate = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        draft.articles = [
            RuleDraft.Article(title: "목적", body: "짧게 회의해요.\n\n기록을 남겨요."),
            RuleDraft.Article(title: "범위", body: "모든 회의")
        ]
        let request = ServerDocWriteRequestDTO(draft, slug: "rule-1", calendar: calendar)
        XCTAssertEqual(request.type, "RULE")
        XCTAssertEqual(request.category, "재무")
        XCTAssertEqual(request.effective, "2026.11.05")
        XCTAssertEqual(request.sections.map(\.title), ["제1조 목적", "제2조 범위"])
        XCTAssertEqual(request.sections[0].lines.map(\.text), ["짧게 회의해요.", "기록을 남겨요."], "빈 줄은 빼요")
        XCTAssertEqual(request.sections.map(\.revised), [false, false], "새 문서는 개정 표시 없음")
        XCTAssertEqual(request.note, "최초 등록")
        XCTAssertEqual(SaveRuleUseCase.newSlug(now: Date(timeIntervalSince1970: 0)), "rule-19700101-090000")
    }

    private func assertInvalid(_ useCase: SaveRuleUseCase, _ draft: RuleDraft, _ message: String,
                               file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await useCase.execute(draft, user: admin)
            XCTFail("저장되면 안 돼요", file: file, line: line)
        } catch {
            XCTAssertEqual(error.userMessage, message, file: file, line: line)
        }
    }
}
