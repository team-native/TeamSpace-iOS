import Foundation

/// 내 활동 가짜 응답 — Figma 07-10 · 07-11 예시 내용 (날짜는 오늘 기준)
enum MockActivityFixture {
    /// 07-12 숫자 중 아직 다른 Mock 저장소가 없는 것
    static let postCount = 3
    static let inquiryCount = 2

    private static func date(_ daysAgo: Double, hour: Double, now: Date) -> String {
        let today = Calendar.current.startOfDay(for: now)
        return ISO8601DateFormatter().string(from: today.addingTimeInterval(-daysAgo * 86_400 + hour * 3_600))
    }

    /// GET /workspace/activity
    static func summary(unreadNotifications: Int, submittedDocuments: Int) -> String {
        """
        {"code":200,"message":"조회 성공","data":{"unreadNotificationCount":\(unreadNotifications),\
        "submittedDocumentCount":\(submittedDocuments),"postCount":\(postCount),"inquiryCount":\(inquiryCount)}}
        """
    }

    /// GET /workspace/posts — 글 3 · 댓글 4
    static func posts(now: Date = Date()) -> String {
        func at(_ days: Double, _ hour: Double) -> String { date(days, hour: hour, now: now) }
        return """
        {"code":200,"message":"조회 성공","data":{"posts":[
          {"id":31,"title":"이번 주 함께 읽을 책 추천해요","createdAt":"\(at(1, 18.33))","isAnonymous":false,\
        "likeCount":8,"commentCount":3,"viewCount":41,"attachmentCount":0},
          {"id":28,"title":"집중해서 일하는 시간, 어떻게 정하나요?","createdAt":"\(at(4, 13.17))","isAnonymous":true,\
        "likeCount":12,"commentCount":6,"viewCount":88,"attachmentCount":0},
          {"id":25,"title":"디자인 리뷰 자료 공유합니다!","createdAt":"\(at(7, 9.5))","isAnonymous":false,\
        "likeCount":5,"commentCount":2,"viewCount":30,"attachmentCount":1}],
        "comments":[
          {"id":301,"postId":22,"postTitle":"회의실 이용 경험을 나눠주세요","body":"예약 기준이 정리되면 좋겠어요.",\
        "createdAt":"\(at(2, 17.08))","isAnonymous":true,"likeCount":2,"replyCount":1},
          {"id":299,"postId":31,"postTitle":"이번 주 함께 읽을 책 추천해요","body":"다음 주엔 제가 한 권 가져올게요!",\
        "createdAt":"\(at(3, 20))","isAnonymous":false,"likeCount":1,"replyCount":0},
          {"id":290,"postId":20,"postTitle":"10월 정기 회의 후기","body":"멘토링 공유 시간이 특히 좋았어요.",\
        "createdAt":"\(at(6, 16.5))","isAnonymous":false,"likeCount":4,"replyCount":2},
          {"id":281,"postId":18,"postTitle":"툴 구독 정리 의견","body":"중복 구독은 분기마다 확인하면 좋겠어요.",\
        "createdAt":"\(at(9, 11))","isAnonymous":true,"likeCount":3,"replyCount":0}]}}
        """
    }

    /// GET /workspace/proposals — 검토 중 2 · 답변 완료 1
    static func proposals(now: Date = Date()) -> String {
        func at(_ days: Double) -> String { date(days, hour: 10, now: now) }
        return """
        {"code":200,"message":"조회 성공","data":{"list":[
          {"id":12,"category":"업무환경","title":"회의실 예약 현황을 한눈에 보고 싶어요",\
        "body":"예약이 겹치는 일이 잦아서, 이번 주 회의실 예약 현황을 앱에서 바로 볼 수 있으면 좋겠어요.",\
        "authorName":"옥물결","createdAt":"\(at(7))","status":"IN_REVIEW","recommendCount":32,"commentCount":2},
          {"id":11,"category":"협업","title":"회의 기록 양식을 통일해요",\
        "body":"Book-on 회의부터 공통 양식을 시범 적용하면 좋겠어요.",\
        "authorName":"옥물결","createdAt":"\(at(9))","status":"IN_REVIEW","recommendCount":18,"commentCount":3},
          {"id":9,"category":"협업","title":"집중 업무 시간을 캘린더에 표시해요",\
        "body":"서로의 집중 시간을 존중할 수 있도록 공통 표기 방식을 제안해요.",\
        "authorName":"옥물결","createdAt":"\(at(14))","status":"ANSWERED","recommendCount":9,"commentCount":2}]}}
        """
    }
}
