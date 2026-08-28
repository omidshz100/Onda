//
//  LiveMeetingView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import Foundation
import SwiftUI

struct LiveMeetingView: View {
    @Environment(\.dismiss) private var dismiss

    let meeting: MeetingSession

    @State private var isMicrophoneEnabled: Bool
    @State private var isCameraEnabled: Bool
    @State private var isShowingParticipants = false
    @State private var isShowingMeetingChat = false

    private let participants = [
        LiveParticipant(name: "Omid", initials: "OS", isSelf: true),
        LiveParticipant(name: "Paolo", initials: "P", isSelf: false),
        LiveParticipant(name: "Rosa", initials: "S", isSelf: false)
    ]

    init(meeting: MeetingSession = .designSync) {
        self.meeting = meeting
        _isMicrophoneEnabled = State(initialValue: meeting.configuration.isMicrophoneEnabled)
        _isCameraEnabled = State(initialValue: meeting.configuration.isCameraEnabled)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isCompact = geometry.size.height < 870
                let mainSpeakerHeight: CGFloat = isCompact ? 378 : 410
                let participantHeight: CGFloat = isCompact ? 132 : 144

                VStack(spacing: 0) {
                    encryptedBadge

                    mainSpeakerCard(height: mainSpeakerHeight)
                        .padding(.top, 16)

                    participantStrip(height: participantHeight)
                        .padding(.top, 16)

                    meetingSummary
                        .padding(.top, isCompact ? 22 : 26)

                    Spacer(minLength: 14)

                    callControls
                }
                .frame(width: max(0, geometry.size.width - 24))
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)
            }
            .background(Palette.liveBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingParticipants) {
                ParticipantsView(meeting: meeting)
            }
            .navigationDestination(isPresented: $isShowingMeetingChat) {
                MeetingChatView(meeting: meeting)
            }
            .preferredColorScheme(.dark)
            .statusBarHidden(false)
        }
    }

    private var encryptedBadge: some View {
        Label("Encrypted", systemImage: "diamond.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.liveSecondaryText)
            .padding(.horizontal, 15)
            .frame(height: 34)
            .background(Palette.liveSurface)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }

    private func mainSpeakerCard(height: CGFloat) -> some View {
        ZStack {
            VStack {
                Spacer()

                Text("M")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(width: 112, height: 112)
                    .background(Palette.brand)
                    .clipShape(Circle())

                Spacer()
            }
            .padding(.bottom, 72)

            VStack {
                Spacer()

                HStack(alignment: .center) {
                    Text("Martina")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Label("Live", systemImage: "waveform")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.liveGreenText)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(Palette.liveGreenSurface)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(Palette.liveSpeakerSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func participantStrip(height: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(participants) { participant in
                ParticipantTile(participant: participant, height: height)
            }
        }
    }

    private var meetingSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(meeting.title)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(1)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let elapsed = max(0, Int(context.date.timeIntervalSince(meeting.startedAt)))
                Text("\(formattedDuration(elapsed)) · \(meeting.participantSummary)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.liveMutedText)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var callControls: some View {
        HStack(spacing: 0) {
            callControl(
                symbol: isMicrophoneEnabled ? "mic.fill" : "mic.slash.fill",
                label: isMicrophoneEnabled ? "Mute microphone" : "Unmute microphone",
                tint: Palette.liveSurface
            ) {
                isMicrophoneEnabled.toggle()
            }

            Spacer()

            callControl(
                symbol: isCameraEnabled ? "video.fill" : "video.slash.fill",
                label: isCameraEnabled ? "Turn camera off" : "Turn camera on",
                tint: Palette.liveSurface
            ) {
                isCameraEnabled.toggle()
            }

            Spacer()

            callControl(
                symbol: "person.2.fill",
                label: "Participants",
                tint: Palette.liveSurface
            ) {
                isShowingParticipants = true
            }

            Spacer()

            callControl(
                symbol: "ellipsis.message.fill",
                label: "Meeting chat",
                tint: Palette.liveSurface
            ) {
                isShowingMeetingChat = true
            }

            Spacer()

            callControl(
                symbol: "xmark",
                label: "End call",
                tint: Palette.callEnd,
                width: 62
            ) {
                dismiss()
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 78)
        .background(Palette.liveControlBar)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 4)
    }

    private func callControl(
        symbol: String,
        label: String,
        tint: Color,
        width: CGFloat = 52,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: width == 62 ? 30 : 24, height: 24)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .tint(tint)
        .foregroundStyle(.white)
        .accessibilityLabel(label)
    }

    private func formattedDuration(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct ParticipantTile: View {
    let participant: LiveParticipant
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(participant.initials)
                .font(.callout.bold())
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(participant.isSelf ? Palette.brand : Palette.liveAvatarMuted)
                .clipShape(Circle())

            Spacer()

            HStack(spacing: 4) {
                Text(participant.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 2)

                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Palette.liveMutedText)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(Palette.liveSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(participant.name), microphone muted")
    }
}

private struct LiveParticipant: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let isSelf: Bool
}

extension Palette {
    static let liveBackground = Color(red: 14 / 255, green: 16 / 255, blue: 22 / 255)
    static let liveSurface = Color(red: 27 / 255, green: 29 / 255, blue: 40 / 255)
    static let liveSpeakerSurface = Color(red: 38 / 255, green: 41 / 255, blue: 54 / 255)
    static let liveControlBar = Color(red: 26 / 255, green: 28 / 255, blue: 38 / 255)
    static let liveAvatarMuted = Color(red: 66 / 255, green: 71 / 255, blue: 92 / 255)
    static let liveSecondaryText = Color(red: 189 / 255, green: 194 / 255, blue: 212 / 255)
    static let liveMutedText = Color(red: 158 / 255, green: 163 / 255, blue: 181 / 255)
    static let liveGreenSurface = Color(red: 23 / 255, green: 92 / 255, blue: 71 / 255)
    static let liveGreenText = Color(red: 153 / 255, green: 255 / 255, blue: 209 / 255)
    static let callEnd = Color(red: 240 / 255, green: 56 / 255, blue: 77 / 255)
}

#Preview {
    LiveMeetingView()
}
