//
//  MainTabView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = AppTab.home
    @State private var profile = OndaProfile.sample

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

            CallsProfileView(profile: $profile)
                .tabItem {
                    Label("Calls", systemImage: "phone.fill")
                }
                .tag(AppTab.calls)

            ChatListView()
            .tabItem {
                Label("Chat", systemImage: "message")
            }
            .tag(AppTab.chat)

            UserProfileView(profile: $profile)
                .tabItem {
                    Label("You", systemImage: "person")
                }
                .tag(AppTab.profile)
        }
        .tint(Palette.brand)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .preferredColorScheme(.light)
    }
}

private enum AppTab: Hashable {
    case home
    case calls
    case chat
    case profile
}

#Preview {
    MainTabView()
}
