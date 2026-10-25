import Foundation

/// 문서함 API 가짜 응답 — Figma 06 문서함 예시 내용
/// 날짜는 오늘 기준으로 계산해서 언제 실행해도 "최근" 문서처럼 보이게 합니다.
enum MockLibraryFixture {
    struct Item {
        let id: Int
        let category: String
        let title: String
        let summary: String
        /// 본문 일부 — 검색(06-2)에서 검색어 주변을 잘라 보여줄 때 사용
        let body: String
        let daysAgo: Double
    }

    static let items: [Item] = [
        Item(id: 1, category: "RULE", title: "Native 프로젝트 운영 원칙", summary: "아이디어 제안부터 출시까지의 기준",
             body: "제안 · 검토 · 개발 · 출시 단계별로 지켜야 할 기준", daysAgo: 5),
        Item(id: 2, category: "FINANCE", title: "외주 수금 및 풀 배분 기준", summary: "운영풀 · 적립풀 · 배당풀 배분과 정산",
             body: "운영풀 · 적립풀 · 배당풀 배분과 정산 방식을 정리해요", daysAgo: 10),
        Item(id: 3, category: "TEMPLATE", title: "예산 품의서", summary: "비용 승인 요청 전에 쓰는 기본 양식",
             body: "물품 · 구독 · 외부 비용 품의를 올릴 때 쓰는 양식", daysAgo: 15),
        Item(id: 4, category: "GUIDE", title: "외주 프로젝트 진행 가이드", summary: "문의 접수부터 납품 · 수금까지",
             body: "문의 접수부터 납품 후 정산 요청 순서", daysAgo: 17),
        Item(id: 5, category: "RULE", title: "회의와 의사결정 원칙", summary: "짧게 논의하고 명확하게 기록하기",
             body: "회의는 30분 안에 끝내고 결정 사항은 바로 기록해요", daysAgo: 22),
        Item(id: 6, category: "FINANCE", title: "운영비 사용 기준", summary: "비품 · 구독 · 행사비 사용 범위",
             body: "운영풀에서 쓸 수 있는 비품 · 구독 · 행사비 범위", daysAgo: 27),
        Item(id: 7, category: "TEMPLATE", title: "프로젝트 인력 지원 요청서", summary: "필요한 직군과 인원을 요청하는 양식",
             body: "프로젝트에 필요한 직군과 인원 수를 요청하는 양식", daysAgo: 30),
        Item(id: 8, category: "RULE", title: "신규 멤버 온보딩 규칙", summary: "합류 첫 2주 동안 하는 일",
             body: "합류 첫 2주 동안 계정 발급 · 멘토 배정 · 첫 회의 참석", daysAgo: 33),
        Item(id: 9, category: "GUIDE", title: "디자인 · 개발 협업 가이드", summary: "핸드오프와 리뷰 순서",
             body: "디자인 핸드오프부터 코드 리뷰까지 협업 순서", daysAgo: 34),
        Item(id: 10, category: "TEMPLATE", title: "정산 요청서", summary: "프로젝트 종료 후 정산을 요청하는 양식",
             body: "프로젝트 종료 후 정산을 요청하는 양식", daysAgo: 35),
        Item(id: 11, category: "FINANCE", title: "법인카드 · 영수증 처리 기준", summary: "증빙 제출과 마감 일정",
             body: "영수증 증빙 제출과 매달 마감 일정", daysAgo: 40),
        Item(id: 12, category: "RULE", title: "보안 · 계정 관리 규칙", summary: "공용 계정과 권한 관리 방법",
             body: "공용 계정 비밀번호와 권한을 관리하는 방법", daysAgo: 45)
    ]

    /// GET /library
    static func library(now: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        func date(_ daysAgo: Double) -> String {
            formatter.string(from: now.addingTimeInterval(-daysAgo * 86_400))
        }
        let list = items.map { documentJSON($0, excerpt: nil, date: date($0.daysAgo)) }.joined(separator: ",")
        return """
        {"code":200,"message":"조회 성공","data":{"list":[\(list)],\
        "latestRevision":{"documentId":1,"title":"프로젝트 운영 원칙","effectiveAt":"\(date(5))"}}}
        """
    }

    static func documentJSON(_ item: Item, excerpt: String?, date: String) -> String {
        let excerptValue = excerpt.map { "\"\($0)\"" } ?? "null"
        return #"{"id":\#(item.id),"category":"\#(item.category)","title":"\#(item.title)","summary":"\#(item.summary)","excerpt":\#(excerptValue),"updatedAt":"\#(date)"}"#
    }
}
