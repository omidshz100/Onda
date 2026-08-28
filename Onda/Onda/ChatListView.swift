//
//  ChatListView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI

struct ChatListView: View {
    @State private var conversations = ChatConversation.samples
    @State private var searchText = ""
    @State private var navigationPath: [ChatConversation] = []
    @State private var isComposingConversation = false

    private var filteredConversations: [ChatConversation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return conversations }

        return conversations.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.lastMessage.localizedCaseInsensitiveContains(query)
        }
    }

    private var pinnedConversations: [ChatConversation] {
        filteredConversations.filter(\.isPinned)
    }

    private var recentConversations: [ChatConversation] {
        filteredConversations.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    searchField

                    if !pinnedConversations.isEmpty {
                        conversationSection(title: "Pinned", conversations: pinnedConversations)
                    }

                    if !recentConversations.isEmpty {
                        conversationSection(title: "Recent", conversations: recentConversations)
                    }

                    if filteredConversations.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Palette.background.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ChatConversation.self) { conversation in
                DirectChatView(conversation: conversation)
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .sheet(isPresented: $isComposingConversation) {
            NewConversationView { conversation in
                withAnimation(.easeInOut(duration: 0.2)) {
                    conversations.insert(conversation, at: 0)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Chat")
                .font(.title.bold())
                .foregroundStyle(Palette.ink)

            Spacer()

            Button {
                isComposingConversation = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.body.weight(.semibold))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .tint(Palette.brand)
            .foregroundStyle(.white)
            .accessibilityLabel("New conversation")
        }
        .frame(height: 40)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)

            TextField("Search conversations", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func conversationSection(
        title: String,
        conversations: [ChatConversation]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Palette.ink)

            VStack(spacing: 0) {
                ForEach(Array(conversations.enumerated()), id: \.element.id) { index, conversation in
                    Button {
                        openConversation(conversation.id)
                    } label: {
                        ChatConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens conversation")

                    if index < conversations.count - 1 {
                        Divider()
                            .padding(.leading, 74)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func openConversation(_ conversationID: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].unreadCount = 0
        navigationPath.append(conversations[index])
    }
}

private struct ChatConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        HStack(spacing: 12) {
            ChatAvatar(initials: conversation.initials, style: conversation.avatarStyle)

            VStack(alignment: .leading, spacing: 3) {
                Text(conversation.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(conversation.lastMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text(conversation.timestamp)
                    .font(.caption2)
                    .foregroundStyle(Palette.secondaryText)

                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Palette.brand)
                        .clipShape(Circle())
                        .accessibilityLabel("\(conversation.unreadCount) unread messages")
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 76)
        .contentShape(Rectangle())
    }
}

private struct ChatAvatar: View {
    let initials: String
    let style: ChatAvatarStyle

    var body: some View {
        Text(initials)
            .font(initials.count > 1 ? .subheadline.weight(.semibold) : .headline)
            .foregroundStyle(style.foreground)
            .frame(width: 48, height: 48)
            .background(style.background)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

private struct NewConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContact: NewChatContact?
    @State private var searchText = ""

    let onCreate: (ChatConversation) -> Void

    private var filteredContacts: [NewChatContact] {
        guard !searchText.isEmpty else { return NewChatContact.samples }
        return NewChatContact.samples.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredContacts) { contact in
                Button {
                    selectedContact = contact
                } label: {
                    HStack(spacing: 12) {
                        ChatAvatar(initials: contact.initials, style: contact.avatarStyle)

                        Text(contact.name)
                            .font(.body)
                            .foregroundStyle(Palette.ink)

                        Spacer()

                        if selectedContact == contact {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Palette.brand)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("New conversation")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search people")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        guard let selectedContact else { return }
                        onCreate(ChatConversation(contact: selectedContact))
                        dismiss()
                    }
                    .disabled(selectedContact == nil)
                }
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
    }
}

struct DirectChatView: View {
    let conversation: ChatConversation

    @State private var messages: [DirectMessage]
    @State private var draft = ""
    @State private var activeMeeting: MeetingSession?
    @FocusState private var isComposerFocused: Bool

    init(conversation: ChatConversation) {
        self.conversation = conversation
        _messages = State(initialValue: DirectMessage.samples(for: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Messages are end-to-end encrypted")
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .padding(.vertical, 8)

                        ForEach(messages) { message in
                            Text(message.text)
                                .font(.subheadline)
                                .foregroundStyle(message.isMine ? Color.white : Palette.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(message.isMine ? Palette.brand : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .frame(maxWidth: 290, alignment: message.isMine ? .trailing : .leading)
                                .frame(maxWidth: .infinity, alignment: message.isMine ? .trailing : .leading)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("direct-chat-bottom")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("direct-chat-bottom", anchor: .bottom)
                    }
                }
            }

            composer
                .padding(.horizontal, 16)
                .padding(.bottom, isComposerFocused ? 8 : 12)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle(conversation.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeMeeting = MeetingSession(
                        title: "Call with \(conversation.name)",
                        participantCount: 2
                    )
                } label: {
                    Image(systemName: "video.fill")
                }
                .accessibilityLabel("Start video call")
            }
        }
        .fullScreenCover(item: $activeMeeting) { meeting in
            LiveMeetingView(meeting: meeting)
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .font(.subheadline)
                .focused($isComposerFocused)
                .lineLimit(1...4)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.body.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        withAnimation {
            messages.append(DirectMessage(text: text, isMine: true))
        }
        draft = ""
    }
}

struct ChatConversation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let initials: String
    let lastMessage: String
    let timestamp: String
    var unreadCount: Int
    let isPinned: Bool
    let avatarStyle: ChatAvatarStyle

    init(
        id: UUID = UUID(),
        name: String,
        initials: String,
        lastMessage: String,
        timestamp: String,
        unreadCount: Int = 0,
        isPinned: Bool,
        avatarStyle: ChatAvatarStyle
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.avatarStyle = avatarStyle
    }

    fileprivate init(contact: NewChatContact) {
        self.init(
            name: contact.name,
            initials: contact.initials,
            lastMessage: "Start a conversation",
            timestamp: "Now",
            isPinned: false,
            avatarStyle: contact.avatarStyle
        )
    }

    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let samples = [
        ChatConversation(
            name: "Product team",
            initials: "P",
            lastMessage: "Sara: The design is ready",
            timestamp: "10:42",
            unreadCount: 3,
            isPinned: true,
            avatarStyle: .brand
        ),
        ChatConversation(
            name: "Martina",
            initials: "M",
            lastMessage: "Sounds good, see you then!",
            timestamp: "09:18",
            isPinned: true,
            avatarStyle: .brandSoft
        ),
        ChatConversation(
            name: "Francesca",
            initials: "F",
            lastMessage: "You: Shared a meeting link",
            timestamp: "Yesterday",
            isPinned: false,
            avatarStyle: .rose
        ),
        ChatConversation(
            name: "Design squad",
            initials: "DS",
            lastMessage: "David: New prototype is ready",
            timestamp: "Tue",
            unreadCount: 2,
            isPinned: false,
            avatarStyle: .brandSoft
        ),
        ChatConversation(
            name: "Alex",
            initials: "A",
            lastMessage: "Thanks!",
            timestamp: "Mon",
            isPinned: false,
            avatarStyle: .neutral
        )
    ]
}

enum ChatAvatarStyle: Hashable {
    case brand
    case brandSoft
    case rose
    case neutral

    var foreground: Color {
        switch self {
        case .brand: .white
        case .brandSoft: Palette.brand
        case .rose: Palette.chatDanger
        case .neutral: Palette.secondaryText
        }
    }

    var background: Color {
        switch self {
        case .brand: Palette.brand
        case .brandSoft: Palette.brandSoft
        case .rose: Palette.chatDangerSoft
        case .neutral: Palette.chatNeutralSoft
        }
    }
}

private struct NewChatContact: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let initials: String
    let avatarStyle: ChatAvatarStyle

    static let samples = [
        NewChatContact(name: "Sara", initials: "S", avatarStyle: .brand),
        NewChatContact(name: "David", initials: "D", avatarStyle: .brandSoft),
        NewChatContact(name: "Paolo", initials: "P", avatarStyle: .neutral),
        NewChatContact(name: "Elena", initials: "E", avatarStyle: .rose)
    ]
}

private struct DirectMessage: Identifiable {
    let id = UUID()
    let text: String
    let isMine: Bool

    static func samples(for conversation: ChatConversation) -> [DirectMessage] {
        [
            DirectMessage(text: "Hi! Are we still on for the meeting?", isMine: false),
            DirectMessage(text: "Yes, I’ll send the link in a moment.", isMine: true),
            DirectMessage(text: conversation.lastMessage.replacingOccurrences(of: "You: ", with: ""), isMine: false)
        ]
    }
}

extension Palette {
    static let chatDanger = Color(red: 240 / 255, green: 56 / 255, blue: 77 / 255)
    static let chatDangerSoft = Color(red: 255 / 255, green: 235 / 255, blue: 237 / 255)
    static let chatNeutralSoft = Color(red: 232 / 255, green: 235 / 255, blue: 245 / 255)
}

#Preview {
    ChatListView()
}
