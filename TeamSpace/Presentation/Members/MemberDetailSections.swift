import SwiftUI

/// 02-4 프로필 — 큰 미모티콘 + 이름 + 칩 + 상태 메시지
struct MemberProfileHeader: View {
    let detail: MemberDetail

    var body: some View {
        VStack(spacing: Spacing.md + Spacing.xxxs) {
            AvatarView(size: 110)
                .padding(5)
                .background(Color.tsSurface, in: Circle())
            VStack(spacing: Spacing.sm) {
                Text(detail.member.name)
                    .tsFont(.title2)
                    .foregroundStyle(Color.tsInk)
                HStack(spacing: Spacing.xs) {
                    ProfileChip(title: detail.member.tag, isAccent: true)
                    ProfileChip(title: detail.member.position, isAccent: false)
                }
                if let message = detail.statusMessage, !message.isEmpty {
                    Text("“\(message)”")
                        .tsFont(.footnote)
                        .foregroundStyle(Color.tsInk3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileChip: View {
    let title: String
    let isAccent: Bool

    var body: some View {
        Text(title)
            .tsFont(isAccent ? .footnoteBold : .footnoteMedium)
            .foregroundStyle(isAccent ? Color.tsPrimary : Color.tsInk2)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 5)
            .background(isAccent ? Color.tsPrimarySoft : Color.tsSurface2, in: Capsule())
    }
}

/// 메일 보내기 · 메시지
struct MemberContactButtons: View {
    let onMail: () -> Void
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm + Spacing.xxxs) {
            Button(action: onMail) {
                Label { Text("메일 보내기") } icon: { TSIcon.mailOutline.sized(.base) }
            }
            .buttonStyle(.ts(.primary, size: .small))
            Button(action: onMessage) {
                Label { Text("메시지") } icon: { TSIcon.message.sized(.base) }
            }
            .buttonStyle(.ts(.secondary, size: .small))
        }
    }
}

/// 부서 · 역할 · 합류 · 이메일
struct MemberInfoCard: View {
    let detail: MemberDetail
    let joinedText: String

    var body: some View {
        VStack(spacing: 0) {
            KeyValueRow(title: "부서", value: detail.member.department.directoryName)
            TSDivider()
            KeyValueRow(title: "역할", value: detail.responsibility)
            TSDivider()
            KeyValueRow(title: "합류", value: joinedText)
            TSDivider()
            KeyValueRow(title: "이메일") {
                Text(detail.email)
                    .tsFont(.calloutBold)
                    .foregroundStyle(Color.tsPrimary)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xxxs)
        .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// 참여 중인 프로젝트
struct MemberProjectsSection: View {
    let projects: [MemberProject]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("참여 중인 프로젝트")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            VStack(spacing: 0) {
                ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                    if index > 0 { TSDivider() }
                    HStack(spacing: Spacing.md) {
                        Text(String(project.name.prefix(1)).uppercased())
                            .tsFont(.bodyBold)
                            .foregroundStyle(project.status == .inProgress ? Color.tsPrimary : Color.tsInk2)
                            .frame(width: 38, height: 38)
                            .background(
                                project.status == .inProgress ? Color.tsPrimarySoft : Color.tsSurface2,
                                in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            )
                        VStack(alignment: .leading, spacing: Spacing.xxxs) {
                            Text(project.name)
                                .tsFont(.calloutBold)
                                .foregroundStyle(Color.tsInk)
                            Text("\(project.summary) · \(project.role)")
                                .tsFont(.caption)
                                .foregroundStyle(Color.tsInk3)
                        }
                        Spacer(minLength: 0)
                        StatusBadge(title: project.status.title, tone: project.status.tone)
                    }
                    .padding(.vertical, Spacing.md + Spacing.xxxs)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .background(Color.tsSurface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

/// 관심사 해시태그
struct MemberInterestsSection: View {
    let interests: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("관심사")
                .tsFont(.headline)
                .foregroundStyle(Color.tsInk)
            FlowLayout {
                ForEach(interests, id: \.self) { interest in
                    Text("# \(interest)")
                        .tsFont(.footnoteMedium)
                        .foregroundStyle(Color.tsInk2)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(Color.tsSurface, in: Capsule())
                }
            }
        }
    }
}
