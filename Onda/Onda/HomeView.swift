//
//  HomeView.swift
//  Onda
//
//  Created by Omid Shojaeian Zanjani on 28/08/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var meetingCode = ""
    @State private var noticeTitle = ""
    @State private var isShowingNotice = false
    @State private var scrollOffset: CGFloat = 0
    @State private var activeMeeting: MeetingSession?
    @FocusState private var isJoinFieldFocused: Bool

    private var isCompactHeaderVisible: Bool {
        scrollOffset > 56
    }

    private let conversations = [
        Conversation(name: "Martina", detail: "Voice call · 18m", initials: "M", style: .primary),
        Conversation(name: "Product team", detail: "12 new messages", initials: "P", style: .soft),
        Conversation(name: "Francesca", detail: "You: See you soon", initials: "F", style: .primary)
    ]

    init(repository: any MeetingRepository = AppEnvironment.live.meetingRepository) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 1)
                        .onGeometryChange(for: CGFloat.self) { geometry in
                            geometry.frame(in: .scrollView(axis: .vertical)).minY
                        } action: { markerY in
                            scrollOffset = max(-markerY, 0)
                        }
                        .accessibilityHidden(true)

                    LazyVStack(spacing: 0) {
                        header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .id(HomeScrollAnchor.top)

                        joinField
                            .padding(.horizontal, 20)
                            .padding(.top, 30)

                        meetingActions
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        upcomingSection
                            .padding(.horizontal, 20)
                            .padding(.top, 38)

                        recentSection
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                            .padding(.bottom, 28)
                    }
                }
                .overlay(alignment: .top) {
                    if isCompactHeaderVisible {
                        compactHeader {
                            revealSearch(using: proxy)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: isCompactHeaderVisible)
            }
            .background(Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .tint(Palette.brand)
            .preferredColorScheme(.light)
            .alert("Onda", isPresented: $isShowingNotice) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(noticeTitle)
            }
        }
        .fullScreenCover(item: $activeMeeting) { meeting in
            LiveMeetingView(meeting: meeting)
        }
        .task {
            await viewModel.loadUpcomingMeetings()
        }
    }

    private func compactHeader(searchAction: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text("Onda")
                .font(.title3.bold())
                .foregroundStyle(Palette.ink)

            Spacer()

            Button(action: searchAction) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(Palette.brand)
            .accessibilityLabel("Open meeting search")

            AvatarView(initials: "OS", style: .primary, size: 36)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Palette.background)
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 7)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.compactHeader")
        .zIndex(1)
    }

    private func revealSearch(using proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.32)) {
            proxy.scrollTo(HomeScrollAnchor.top, anchor: .top)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            isJoinFieldFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Onda")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Palette.ink)

                Text("Your space to meet and talk")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer()

            AvatarView(initials: "OS", style: .primary, size: 48)
                .padding(.top, 2)
        }
    }

    private var joinField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(Palette.secondaryText)

            TextField("Enter a code or link", text: $meetingCode)
                .font(.body)
                .foregroundStyle(Palette.ink)
                .focused($isJoinFieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit {
                    joinMeeting()
                }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var meetingActions: some View {
        HStack(spacing: 14) {
            NavigationLink {
                NewMeetingView()
            } label: {
                Label("New meeting", systemImage: "plus")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Palette.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            actionButton(
                title: "Schedule",
                symbol: "calendar",
                foreground: Palette.brand,
                background: Palette.brandSoft
            ) {
                showNotice("The Schedule screen will be implemented later.")
            }
        }
    }

    private var upcomingSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Upcoming", actionTitle: "See all") {
                showNotice("The complete meeting list will be implemented later.")
            }

            UpcomingMeetingCard(meeting: viewModel.featuredMeeting) {
                activeMeeting = viewModel.featuredMeeting
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent conversations")
                .font(.title2.bold())
                .foregroundStyle(Palette.ink)

            LazyVStack(spacing: 12) {
                ForEach(conversations) { conversation in
                    NavigationLink {
                        DirectChatView(conversation: conversation.chatConversation)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(
        title: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Palette.ink)

            Spacer()

            Button(actionTitle, action: action)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func actionButton(
        title: String,
        symbol: String,
        foreground: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.callout.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func showNotice(_ message: String) {
        noticeTitle = message
        isShowingNotice = true
    }

    private func joinMeeting() {
        let code = meetingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            showNotice("Enter a meeting code or link first.")
            return
        }

        activeMeeting = MeetingSession(
            title: "Joined meeting",
            code: code,
            participantCount: 1
        )
        meetingCode = ""
        isJoinFieldFocused = false
    }
}

private enum HomeScrollAnchor: Hashable {
    case top
}

private struct UpcomingMeetingCard: View {
    let meeting: MeetingSession
    let joinAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(meeting.title)
                .font(.title3.bold())
                .foregroundStyle(Palette.ink)

            Text(scheduleText)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .padding(.top, 5)

            Spacer(minLength: 18)

            HStack {
                Text("OS  +3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.brand)
                    .padding(.horizontal, 13)
                    .frame(height: 36)
                    .background(Palette.brandSoft)
                    .clipShape(Capsule())

                Spacer()

                Button("Join", action: joinAction)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 78, height: 40)
                    .background(Palette.brand)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .leading)
        .background(Color.white)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Palette.brand)
                .frame(width: 7)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var scheduleText: String {
        let day = Calendar.current.isDateInToday(meeting.startedAt)
            ? "Today"
            : meeting.startedAt.formatted(.dateTime.month(.abbreviated).day())
        let start = meeting.startedAt.formatted(date: .omitted, time: .shortened)
        let end = meeting.startedAt
            .addingTimeInterval(45 * 60)
            .formatted(date: .omitted, time: .shortened)
        return "\(day) · \(start) – \(end)"
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(initials: conversation.initials, style: conversation.style, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)

                Text(conversation.detail)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AvatarView: View {
    let initials: String
    let style: AvatarStyle
    let size: CGFloat

    var body: some View {
        Text(initials)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(style.foreground)
            .frame(width: size, height: size)
            .background(style.background)
            .clipShape(Circle())
            .accessibilityLabel("\(initials) avatar")
    }
}

private struct Conversation: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let initials: String
    let style: AvatarStyle

    var chatConversation: ChatConversation {
        ChatConversation(
            id: id,
            name: name,
            initials: initials,
            lastMessage: detail,
            timestamp: "",
            isPinned: false,
            avatarStyle: style == .primary ? .brand : .brandSoft
        )
    }
}

enum AvatarStyle: Equatable {
    case primary
    case soft

    var foreground: Color {
        switch self {
        case .primary: .white
        case .soft: Palette.brand
        }
    }

    var background: Color {
        switch self {
        case .primary: Palette.brand
        case .soft: Palette.brandSoft
        }
    }
}

enum Palette {
    static let background = Color(red: 246 / 255, green: 247 / 255, blue: 252 / 255)
    static let ink = Color(red: 20 / 255, green: 23 / 255, blue: 36 / 255)
    static let secondaryText = Color(red: 99 / 255, green: 105 / 255, blue: 128 / 255)
    static let brand = Color(red: 89 / 255, green: 71 / 255, blue: 245 / 255)
    static let brandSoft = Color(red: 232 / 255, green: 229 / 255, blue: 255 / 255)
    static let border = Color(red: 227 / 255, green: 229 / 255, blue: 240 / 255)
}

#Preview {
    HomeView()
}
