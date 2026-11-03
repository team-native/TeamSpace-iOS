import Foundation

/// 내 공간 저장소
/// 명세서에는 `GET /workspace/todos` 만 있어 대시보드 요약 경로는 임시로 정했습니다. (백엔드와 맞춰야 함)
protocol WorkspaceRepository: Sendable {
    /// GET /workspace/home — 07-1 내 공간 대시보드 요약
    func fetchHome() async throws -> WorkspaceHome
    /// GET /me/projects — 07-6 참여 프로젝트
    func fetchJoinedProjects() async throws -> [JoinedProject]
    /// GET /approvals?box=mine — 07-4 내가 제출한 문서 · 07-5 임시 저장
    func fetchMyDocuments() async throws -> [MyDocument]
    /// POST /approvals/{id}/cancel — 07-5 임시 저장 삭제 (서버에 삭제가 없어 취소)
    func deleteDraft(documentId: Int) async throws
    /// GET /events?month=yyyy-MM — 07-7 한 달 일정
    func fetchSchedules(month: Date) async throws -> [ScheduleEvent]
    /// POST /admin/events — 일정 추가 (Admin), 만든 일정 id
    func createSchedule(_ draft: ScheduleDraft) async throws -> Int
    /// GET /events/{id} · GET /events/{id}/reminders — 07-8 일정 상세
    func fetchScheduleDetail(id: Int) async throws -> ScheduleEventDetail
    /// POST /events/{id}/rsvp — 참석 · 불참 · 미정
    func respond(scheduleId: Int, response: ScheduleResponse) async throws -> ScheduleEvent
    /// PATCH /events/{id}/reminders — 07-8 내 리마인더
    func updateReminders(scheduleId: Int, reminders: [ReminderTiming]) async throws -> [ReminderTiming]
    /// GET /me/summary — 07-12 내 활동 숫자
    func fetchActivitySummary() async throws -> ActivitySummary
    /// GET /posts?mine=true · GET /me/activity(댓글) — 07-10 내가 쓴 글 · 댓글
    func fetchMyPosts() async throws -> MyPosts
    /// GET /proposals 중 mine — 07-11 내가 작성한 운영 제안
    func fetchMyProposals() async throws -> [MyProposal]
    /// GET /me — 07-13 내 프로필
    func fetchProfile() async throws -> MyProfile
    /// PATCH /me — 한 줄 소개(bio) · 관심사 · 배경색 저장 (배경색은 서버에 아직 없음)
    func updateProfile(_ update: ProfileUpdate) async throws -> MyProfile
    /// PATCH /me/settings — 비밀번호 변경 (현재 비밀번호가 다르면 400)
    func changePassword(current: String, new: String) async throws
    /// GET /todos — 사용자 할 일 목록 (받은 결재 할 일 포함)
    func fetchTodos() async throws -> [TodoItem]
    /// POST /todos — 할 일 추가
    func addTodo(_ draft: TodoDraft) async throws -> TodoItem
    /// PATCH /todos/{todoId} — 완료 · 되돌리기
    func updateTodo(id: Int, status: TodoStatus) async throws -> TodoItem
}
