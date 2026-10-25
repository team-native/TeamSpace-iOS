import SwiftUI

extension Department {
    /// 03 팀원 화면의 부서 칩 이름
    var directoryName: String {
        switch self {
        case .leader: return "Leader"
        case .nativeOps: return "NativeOps"
        case .pmo: return "PMO"
        case .fa: return "FA"
        case .design: return "Design"
        case .dev: return "Dev"
        case .unknown: return "기타"
        }
    }

    /// 이름 옆 칩 · 조직도 인원 칩 색
    var tone: BadgeTone {
        switch self {
        case .leader: return .amber
        case .nativeOps: return .positive
        case .pmo: return .primary
        case .fa: return .warning
        case .design: return .violet
        case .dev: return .primary
        case .unknown: return .neutral
        }
    }
}

extension MemberProject.Status {
    var title: String {
        switch self {
        case .inProgress: return "진행 중"
        case .completed: return "완료"
        case .unknown: return "확인 필요"
        }
    }

    var tone: BadgeTone {
        switch self {
        case .inProgress: return .primary
        case .completed, .unknown: return .neutral
        }
    }
}

/// 목록 / 조직도 전환
enum MemberDirectoryMode: Hashable, CaseIterable {
    case list
    case organization

    var title: String {
        switch self {
        case .list: return "목록"
        case .organization: return "조직도"
        }
    }
}

/// 부서 필터 칩 — 전체 + 부서
enum MemberDepartmentFilter: Hashable {
    case all
    case department(Department)

    func matches(_ member: Member) -> Bool {
        switch self {
        case .all: return true
        case .department(let department): return member.department == department
        }
    }
}

/// 팀원 한 줄 — 미모티콘 + 이름 · 칩 + 직책
struct MemberRow: View {
    let member: Member

    var body: some View {
        HStack(spacing: Spacing.md) {
            AvatarView(size: 40)
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack(spacing: Spacing.xs) {
                    Text(member.name)
                        .tsFont(.calloutBold)
                        .foregroundStyle(Color.tsInk)
                    StatusBadge(title: member.tag, tone: member.department.tone)
                }
                Text(member.position)
                    .tsFont(.caption)
                    .foregroundStyle(Color.tsInk3)
            }
            Spacer(minLength: 0)
            TSIcon.chevronRight.sized(.mdLarge)
                .foregroundStyle(Color.tsInk3)
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
