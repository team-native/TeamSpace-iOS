import Foundation

enum MockTemplateFixture {
    static func template(id: Int) -> String? {
        switch id {
        case 3:
            return """
            {"code":200,"message":"조회 성공","data":{
              "id":3,"title":"예산 품의서",
              "description":"비용 승인 요청 전에 쓰는 기본 양식이에요.\\n작성하면 바로 결재로 이어져요.",
              "monthlyUsageCount":12,"formKind":"EXPENSE",
              "fields":[
                {"title":"비용 유형","subtitle":"물품 · 구독 · 외부 비용"},
                {"title":"요청 금액과 사용일","subtitle":"부가세 포함 금액"},
                {"title":"요청 사유","subtitle":"목적과 기대 효과"},
                {"title":"첨부","subtitle":"견적서 · 영수증"}]
            }}
            """
        case 7:
            return """
            {"code":200,"message":"조회 성공","data":{
              "id":7,"title":"프로젝트 인력 지원 요청서",
              "description":"프로젝트에 필요한 직군과 인원을 요청하는 양식이에요.",
              "monthlyUsageCount":8,"formKind":"STAFFING",
              "fields":[
                {"title":"프로젝트","subtitle":"지원이 필요한 프로젝트"},
                {"title":"직군과 인원","subtitle":"필요한 역할과 인원 수"},
                {"title":"지원 기간과 사유","subtitle":"진행 일정과 요청 목적"}]
            }}
            """
        case 10:
            return """
            {"code":200,"message":"조회 성공","data":{
              "id":10,"title":"정산 요청서",
              "description":"프로젝트 종료 후 정산 내용을 작성해 결재를 요청해요.",
              "monthlyUsageCount":4,"formKind":"SETTLEMENT",
              "fields":[
                {"title":"문서 제목","subtitle":"정산할 프로젝트와 요청 제목"},
                {"title":"정산 내용","subtitle":"금액 · 사용 내역 · 정산 사유"},
                {"title":"첨부","subtitle":"영수증 · 정산 증빙"}]
            }}
            """
        default:
            return nil
        }
    }
}
