import SwiftUI

/// Figma `TabBar` — 하단 플로팅 캡슐 탭바
struct TSTabBarItem: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: TSIcon
}

struct TSTabBar: View {
    let items: [TSTabBarItem]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(item)
            }
        }
        .padding(Spacing.xs)
        .background(Color.tsSurface, in: Capsule())
        .tsShadow(.raised)
        .padding(.horizontal, Spacing.screen)
    }

    private func tabButton(_ item: TSTabBarItem) -> some View {
        let isSelected = item.id == selection
        return Button {
            selection = item.id
        } label: {
            VStack(spacing: Spacing.xxxs) {
                item.icon.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(item.title)
                    .tsFont(isSelected ? .tabLabelSelected : .tabLabel)
            }
            .foregroundStyle(isSelected ? Color.tsOnPrimary : Color.tsInk3)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(isSelected ? Color.tsPrimary : Color.clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TSTabBarPreview: View {
    @State private var selection = "finance"

    var body: some View {
        TSTabBar(
            items: [
                TSTabBarItem(id: "home", title: "홈", icon: .tabHome),
                TSTabBarItem(id: "finance", title: "재무", icon: .tabFinance),
                TSTabBarItem(id: "approval", title: "결재", icon: .tabApproval),
                TSTabBarItem(id: "documents", title: "문서함", icon: .tabDocuments),
                TSTabBarItem(id: "workspace", title: "내 공간", icon: .tabWorkspace)
            ],
            selection: $selection
        )
    }
}

#Preview {
    TSTabBarPreview()
        .padding(.vertical)
        .background(Color.tsBackground)
}
