//
//  ParticipantsView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI

struct ParticipantsView: View {
    let meeting: MeetingSession

    @State private var searchText = ""
    @State private var participants = MeetingParticipant.initialParticipants
    @State private var waitingPeople = WaitingParticipant.initialWaitingPeople
    @State private var notice = ""
    @State private var isShowingNotice = false

    private var filteredParticipants: [MeetingParticipant] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return participants
        }

        return participants.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.status.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                searchField

                sectionTitle("In this meeting")
                    .padding(.top, 26)

                participantList
                    .padding(.top, 12)

                if !waitingPeople.isEmpty {
                    sectionTitle("People waiting")
                        .padding(.top, 38)

                    waitingList
                        .padding(.top, 12)
                }

                inviteButton
                    .padding(.top, waitingPeople.isEmpty ? 38 : 52)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("Participants")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(participants.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.brand)
                    .frame(minWidth: 34, minHeight: 32)
                    .padding(.horizontal, 6)
                    .background(Palette.brandSoft)
                    .clipShape(Capsule())
                    .accessibilityLabel("\(participants.count) participants")
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .alert("Onda", isPresented: $isShowingNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notice)
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(Palette.secondaryText)

            TextField("Search participants", text: $searchText)
                .font(.body)
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
        .padding(.horizontal, 17)
        .frame(height: 52)
        .background(Palette.participantSearch)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var participantList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredParticipants) { participant in
                ParticipantRow(
                    participant: participant,
                    toggleMute: { toggleMute(for: participant.id) },
                    remove: { removeParticipant(participant) },
                    showDetails: { showNotice("You are the host of this meeting.") }
                )
            }

            if filteredParticipants.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, minHeight: 136)
            }
        }
    }

    private var waitingList: some View {
        LazyVStack(spacing: 12) {
            ForEach(waitingPeople) { person in
                WaitingParticipantRow(
                    participant: person,
                    deny: { deny(person) },
                    admit: { admit(person) }
                )
            }
        }
    }

    private var inviteButton: some View {
        ShareLink(item: invitationURL) {
            Label("Invite people", systemImage: "person.badge.plus")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Palette.brand)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var invitationURL: URL {
        if let code = meeting.code?.trimmingCharacters(in: .whitespacesAndNewlines),
           let suppliedURL = URL(string: code),
           suppliedURL.scheme != nil {
            return suppliedURL
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "onda.app"
        components.path = "/meet/\(meeting.code ?? meeting.id.uuidString.lowercased())"
        return components.url ?? URL(string: "https://onda.app/meet")!
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.ink)
    }

    private func toggleMute(for id: UUID) {
        guard let index = participants.firstIndex(where: { $0.id == id }),
              !participants[index].isSelf else { return }

        participants[index].isMuted.toggle()
        participants[index].isSpeaking = false
    }

    private func removeParticipant(_ participant: MeetingParticipant) {
        guard !participant.isSelf else { return }
        withAnimation {
            participants.removeAll { $0.id == participant.id }
        }
    }

    private func deny(_ person: WaitingParticipant) {
        withAnimation {
            waitingPeople.removeAll { $0.id == person.id }
        }
        showNotice("\(person.name)'s request was declined.")
    }

    private func admit(_ person: WaitingParticipant) {
        withAnimation {
            waitingPeople.removeAll { $0.id == person.id }
            participants.append(
                MeetingParticipant(
                    name: person.name,
                    initials: person.initials,
                    status: "Microphone off",
                    avatarColor: person.avatarColor,
                    isMuted: true
                )
            )
        }
        showNotice("\(person.name) joined the meeting.")
    }

    private func showNotice(_ message: String) {
        notice = message
        isShowingNotice = true
    }
}

private struct ParticipantRow: View {
    let participant: MeetingParticipant
    let toggleMute: () -> Void
    let remove: () -> Void
    let showDetails: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            participant.avatar

            VStack(alignment: .leading, spacing: 3) {
                Text(participant.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(participant.status)
                    .font(.caption)
                    .foregroundStyle(participant.isSpeaking ? Palette.success : Palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if !participant.isSelf {
                Image(systemName: participant.isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: 24, height: 32)
                    .accessibilityLabel(participant.isMuted ? "Microphone off" : "Microphone on")
            }

            Menu {
                if participant.isSelf {
                    Button("Meeting details", systemImage: "info.circle", action: showDetails)
                } else {
                    Button(
                        participant.isMuted ? "Ask to unmute" : "Mute participant",
                        systemImage: participant.isMuted ? "mic.fill" : "mic.slash.fill",
                        action: toggleMute
                    )

                    Button("Remove from meeting", systemImage: "person.badge.minus", role: .destructive, action: remove)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: 30, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options for \(participant.name)")
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 68, maxHeight: 68)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct WaitingParticipantRow: View {
    let participant: WaitingParticipant
    let deny: () -> Void
    let admit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            participant.avatar

            VStack(alignment: .leading, spacing: 3) {
                Text(participant.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)

                Text(participant.requestedAt)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 4)

            Button(role: .destructive, action: deny) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.callEnd)
                    .frame(width: 44, height: 40)
                    .background(Palette.denyBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Decline \(participant.name)")

            Button(action: admit) {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 40)
                    .background(Palette.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Admit \(participant.name)")
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 82)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct MeetingParticipant: Identifiable {
    let id: UUID
    let name: String
    let initials: String
    var status: String
    let avatarColor: Color
    let isSelf: Bool
    var isMuted: Bool
    var isSpeaking: Bool

    init(
        id: UUID = UUID(),
        name: String,
        initials: String,
        status: String,
        avatarColor: Color,
        isSelf: Bool = false,
        isMuted: Bool,
        isSpeaking: Bool = false
    ) {
        self.id = id
        self.name = name
        self.initials = initials
        self.status = status
        self.avatarColor = avatarColor
        self.isSelf = isSelf
        self.isMuted = isMuted
        self.isSpeaking = isSpeaking
    }

    var avatar: some View {
        Text(initials)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(avatarColor)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    static let initialParticipants = [
        MeetingParticipant(
            name: "You (Omid)",
            initials: "OS",
            status: "Host · Microphone on",
            avatarColor: Palette.brand,
            isSelf: true,
            isMuted: false
        ),
        MeetingParticipant(
            name: "Martina",
            initials: "M",
            status: "Speaking now",
            avatarColor: Palette.brand,
            isMuted: true,
            isSpeaking: true
        ),
        MeetingParticipant(
            name: "Paolo",
            initials: "P",
            status: "Microphone off",
            avatarColor: Palette.liveAvatarMuted,
            isMuted: true
        ),
        MeetingParticipant(
            name: "Sara",
            initials: "S",
            status: "Microphone off",
            avatarColor: Palette.liveAvatarMuted,
            isMuted: true
        )
    ]
}

private struct WaitingParticipant: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let requestedAt: String
    let avatarColor: Color

    var avatar: some View {
        Text(initials)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(avatarColor)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    static let initialWaitingPeople = [
        WaitingParticipant(
            name: "Luca",
            initials: "L",
            requestedAt: "Requested 1m ago",
            avatarColor: Palette.waitingAvatar
        )
    ]
}

extension Palette {
    static let participantSearch = Color(red: 240 / 255, green: 241 / 255, blue: 247 / 255)
    static let waitingAvatar = Color(red: 242 / 255, green: 158 / 255, blue: 46 / 255)
    static let denyBackground = Color(red: 247 / 255, green: 232 / 255, blue: 235 / 255)
}

#Preview {
    NavigationStack {
        ParticipantsView(meeting: .designSync)
    }
}
