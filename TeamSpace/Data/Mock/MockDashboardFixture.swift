import Foundation

/// GET /dashboard/home 가짜 응답 — Figma 02-1 홈 예시 내용.
/// 날짜는 오늘 기준으로 만들어서 D-day · "어제 업데이트" 가 항상 자연스럽게 보이게 합니다.
enum MockDashboardFixture {
    static func json(now: Date = Date()) -> String {
        func at(days: Double, hours: Double = 0) -> String {
            ISO8601DateFormatter().string(from: now.addingTimeInterval(days * 86_400 + hours * 3_600))
        }
        return """
        {"code":200,"message":"조회 성공","data":{
          "todayTaskCount":3,
          "unreadNotificationCount":3,
          "latestNotification":{"type":"APPROVAL","title":"새 결재 요청이 도착했어요",\
        "subtitle":"이시우 · 프로젝트 인력 지원","createdAt":"\(at(days: 0, hours: -0.01))"},
          "finance":{"month":"\(at(days: 0))","availableAmount":3560000,"holdingAmount":8900000,"changeRate":12.8,
            "trend":[2100000,2400000,2250000,2700000,2600000,3050000,2900000,3300000,3560000],
            "pools":[{"kind":"OPERATION","ratio":40,"amount":3560000},
                     {"kind":"RESERVE","ratio":30,"amount":2670000},
                     {"kind":"DIVIDEND","ratio":30,"amount":2670000}],
            "monthIncome":7260000,"monthExpense":3480000},
          "contracts":{"totalAmount":12700000,"yearCount":9,
            "pools":[{"kind":"OPERATION","ratio":40,"amount":3560000,"count":2},
                     {"kind":"RESERVE","ratio":30,"amount":2670000,"count":3}],
            "recentContracts":[
              {"id":1,"title":"예약 서비스 앱 UI 제작","amount":4200000,"contractedAt":"\(at(days: -4))","status":"CONTRACTED"},
              {"id":2,"title":"IoT 학과 홍보 웹 페이지","amount":1309000,"contractedAt":"\(at(days: -5))","status":"CONTRACTED"}],
            "recentDeposits":[
              {"id":11,"title":"먼작귀 포켓앱 UI 제작","kind":"선금","amount":800000,"paidAt":"\(at(days: -4))"},
              {"id":12,"title":"카피바라 키우기 제작","kind":"선금","amount":4200000,"paidAt":"\(at(days: -10))"}]},
          "projects":[
            {"id":21,"name":"먼작귀 포켓앱 UI 제작","memberCount":5,"dueDate":"\(at(days: 27))","progress":35},
            {"id":22,"name":"MoSS","memberCount":6,"dueDate":"\(at(days: 14))","progress":60}],
          "schedules":[
            {"id":31,"title":"주간 팀 회의","place":"온라인","startsAt":"\(at(days: 1))"},
            {"id":32,"title":"IoT 학과 홍보 홈페이지 납품","place":"내부 운영 플랫폼","startsAt":"\(at(days: 12))"}],
          "notices":[
            {"id":41,"category":"FINANCE","title":"10월 프로젝트 정산 기준 안내","updatedAt":"\(at(days: -1))"},
            {"id":42,"category":"RULE","title":"외주 프로젝트 착수 전 체크리스트","updatedAt":"\(at(days: -3))"},
            {"id":43,"category":"NOTICE","title":"NativeLab 계약서 작성 가이드","updatedAt":"\(at(days: -15))"}]
        }}
        """
    }
}
