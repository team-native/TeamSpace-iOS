import Foundation

/// 내 공간 API 가짜 응답 — Figma 07 My Workspace 예시 내용
/// 날짜는 오늘 기준으로 만들어서 "예정 일정" 이 항상 앞으로의 일정처럼 보이게 합니다.
/// 결재 문서 ID 는 MockApprovalStore 와 같아서 눌러 보면 05 결재 상세가 열려요.
enum MockWorkspaceFixture {
    /// GET /me/projects — `{id, ...프로젝트 payload}` 그대로
    static func projects() -> String {
        """
        {"items":[
          {"id":"1","slug":"book-on","name":"Book-on","desc":"독서 기록 앱 · 그린랩 외주 · 2026.07 – 2026.11","role":"iOS 리드",\
        "progress":68,"status":"진행 중","tone":"blue","due":"11.20 납품","pm":"박도윤","memberIds":["1"]},
          {"id":"3","name":"Native 팀스페이스","desc":"내부 운영 플랫폼","role":"PO","progress":85,"status":"마무리",\
        "tone":"green","due":"12.04 오픈","pm":"김준표","memberIds":["1"]}
        ],"nextCursor":null}
        """
    }
}
