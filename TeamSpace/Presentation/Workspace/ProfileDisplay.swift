import SwiftUI

extension AvatarBackground {
    var color: Color {
        switch self {
        case .gray, .unknown: return .tsSurface2
        case .blue: return .tsPrimarySoft
        case .yellow: return .tsAmberSoft
        case .green: return .tsPositiveSoft
        case .pink: return .tsNegativeSoft
        }
    }
}

/// 07-13 미모티콘 — 고른 사진이 있으면 사진, 없으면 기본 얼굴
struct ProfileAvatar: View {
    let imageData: Data?
    let background: AvatarBackground
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            Circle().fill(background.color)
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.48))
                    .foregroundStyle(Color.tsInk3)
                    .offset(y: size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("내 미모티콘")
    }
}

extension AuthUser {
    /// 07-15 "구성원" · "PM" · "Leader" …
    var roleTitle: String {
        let roles = Set(roles)
        if roles.contains(.admin) { return "관리자" }
        if roles.contains(.leader) { return "Leader" }
        if roles.contains(.fa) { return "FA" }
        if roles.contains(.pm) { return "PM" }
        return "구성원"
    }

    /// 07-15 추가 운영 권한 — 없으면 "없음"
    var extraPermissionText: String {
        let names: [(Permission, String)] = [
            (.approveDocument, "결재"),
            (.manageProject, "프로젝트 관리"),
            (.viewFinanceDetail, "재정 상세 열람"),
            (.answerInquiry, "문의 답변"),
            (.publishNotice, "전체 공지")
        ]
        let granted = names.filter { can($0.0) }.map(\.1)
        return granted.isEmpty ? "없음" : granted.joined(separator: " · ")
    }

    /// 07-15 허용되는 기능 — 모두에게 열린 기능 + 내 역할로 더 할 수 있는 일
    var allowedFeatures: [String] {
        var features = [
            "내 알림·프로필·일정 확인",
            "문서 작성·제출, 내 문서 결과 확인",
            "프로젝트 탐색·참여 신청",
            "게시글·댓글 실명/익명 선택 작성",
            "공식 문의 제출·내 문의 확인",
            "공개 규칙·재정 요약 열람"
        ]
        if can(.approveDocument) { features.append("지정된 결재 승인·반려") }
        if can(.manageProject) { features.append("담당 프로젝트 편집·지원자 검토") }
        if can(.viewFinanceDetail) { features.append("허용된 재정 세부 내역 열람") }
        if can(.answerInquiry) { features.append("배정된 문의에 공식 답변") }
        if can(.publishNotice) { features.append("전체 공지 작성·예약 게시") }
        return features
    }
}
