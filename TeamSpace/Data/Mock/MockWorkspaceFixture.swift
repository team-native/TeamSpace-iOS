import Foundation

/// 내 공간 API 가짜 응답 — Figma 07 My Workspace 예시 내용
/// 날짜는 오늘 기준으로 만들어서 "예정 일정" 이 항상 앞으로의 일정처럼 보이게 합니다.
/// 결재 문서 ID 는 MockApprovalStore 와 같아서 눌러 보면 05 결재 상세가 열려요.
enum MockWorkspaceFixture {
    /// GET /workspace/home
    static func home(now: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = ISO8601DateFormatter()
        let today = calendar.startOfDay(for: now)
        func at(days: Int, hour: Int) -> String {
            let day = calendar.date(byAdding: .day, value: days, to: today) ?? today
            return formatter.string(from: day.addingTimeInterval(TimeInterval(hour) * 3_600))
        }
        let shortDate = DateFormatter()
        shortDate.locale = Locale(identifier: "ko_KR")
        shortDate.dateFormat = "MM.dd"
        let qaDay = shortDate.string(from: calendar.date(byAdding: .day, value: 7, to: today) ?? today)
        return """
        {"code":200,"message":"조회 성공","data":{
          "affiliation":"NativeLab / Design",
          "todo":{"todayCount":2,"completedCount":1,"todayTitles":["QA 체크리스트 정리","인원 지원 요청 검토"]},
          "notification":{"unreadCount":3,"title":"Book-on QA 일정이 변경됐어요","subtitle":"\(qaDay) 15:00–16:00 · 온라인"},
          "receivedApproval":{"documentId":11,"waitingCount":1,"title":"Book-on 프로젝트 인력 지원",\
        "requesterName":"이시우","requestedAt":"\(at(days: 0, hour: 9))"},
          "submittedDocument":{"documentId":1,"title":"Book-on 테스트 기기 구매","amount":420000,\
        "submittedAt":"\(at(days: -2, hour: 10))","status":"IN_REVIEW","currentApproverName":"이시우"},
          "projects":[
            {"id":1,"name":"Book-on","pmName":"이시우","team":"NativeLab","memberCount":6,"progress":68},
            {"id":2,"name":"BRIDGE","pmName":"오잉","team":"NativeLab","memberCount":4,"progress":80}],
          "schedules":[
            {"id":2,"scope":"TEAM","title":"Native 전체 회의","startsAt":"\(at(days: 8, hour: 14))",\
        "endsAt":"\(at(days: 8, hour: 16))","place":"4층 홈베이스","note":"NativeOps"},
            {"id":1,"scope":"PERSONAL","title":"Book-on QA 점검","startsAt":"\(at(days: 7, hour: 15))",\
        "endsAt":"\(at(days: 7, hour: 16))","place":"온라인","note":"변경자 이시우"}],
          "records":{
            "latestPost":{"title":"이번 주 함께 읽을 책 추천해요","createdAt":"\(at(days: -1, hour: 20))"},
            "proposalCount":3,
            "latestProposal":{"title":"회의실 예약 현황을 한눈에 보고 싶어요","status":"IN_REVIEW","recommendCount":32},
            "inquiries":[{"title":"회의실 예약 기준","status":"ANSWERED"},{"title":"안내 자료","status":"IN_REVIEW"}]}
        }}
        """
    }
}
