//
//  NewMeetingView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI

struct NewMeetingView: View {
    @State private var meetingName = "Friday product review"
    @State private var isWaitingRoomEnabled = true
    @State private var isMicrophoneEnabled = true
    @State private var isCameraEnabled = false
    @State private var isSpeakerEnabled = true
    @State private var activeMeeting: MeetingSession?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Preview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)

                cameraPreview
                    .padding(.top, 14)

                meetingNameField
                    .padding(.top, 38)

                waitingRoomRow
                    .padding(.top, 18)

                startMeetingButton
                    .padding(.top, 34)

                Text("Anyone with the link can request to join")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("New meeting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .fullScreenCover(item: $activeMeeting) { meeting in
            LiveMeetingView(meeting: meeting)
        }
    }

    private var cameraPreview: some View {
        VStack(spacing: 0) {
            AvatarView(initials: "OS", style: .primary, size: 88)

            Text(isCameraEnabled ? "Camera is on" : "Camera is off")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.previewPrimaryText)
                .padding(.top, 18)

            Text(isCameraEnabled ? "You’re ready to join" : "Turn it on when you’re ready")
                .font(.caption)
                .foregroundStyle(Palette.previewSecondaryText)
                .padding(.top, 5)

            HStack(spacing: 26) {
                previewControl(
                    symbol: isMicrophoneEnabled ? "mic.fill" : "mic.slash.fill",
                    accessibilityLabel: isMicrophoneEnabled ? "Mute microphone" : "Unmute microphone"
                ) {
                    isMicrophoneEnabled.toggle()
                }

                previewControl(
                    symbol: isCameraEnabled ? "video.fill" : "video.slash.fill",
                    accessibilityLabel: isCameraEnabled ? "Turn camera off" : "Turn camera on"
                ) {
                    isCameraEnabled.toggle()
                }

                previewControl(
                    symbol: isSpeakerEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    accessibilityLabel: isSpeakerEnabled ? "Turn speaker off" : "Turn speaker on"
                ) {
                    isSpeakerEnabled.toggle()
                }
            }
            .padding(.top, 35)
        }
        .padding(.top, 86)
        .frame(maxWidth: .infinity, minHeight: 348, alignment: .top)
        .background(Palette.previewBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var meetingNameField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Meeting name")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)

            TextField("Meeting name", text: $meetingName)
                .font(.body)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 17)
                .frame(height: 58)
                .background(Color.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Palette.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var waitingRoomRow: some View {
        Toggle(isOn: $isWaitingRoomEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Waiting room")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)

                Text("Approve people before they join")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .tint(Palette.success)
        .padding(.horizontal, 18)
        .frame(minHeight: 68)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var startMeetingButton: some View {
        Button {
            startMeeting()
        } label: {
            Text("Start meeting")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Palette.brand)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(meetingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(meetingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
    }

    private func startMeeting() {
        let title = meetingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        activeMeeting = MeetingSession(
            title: title,
            configuration: MeetingConfiguration(
                usesWaitingRoom: isWaitingRoomEnabled,
                isMicrophoneEnabled: isMicrophoneEnabled,
                isCameraEnabled: isCameraEnabled,
                isSpeakerEnabled: isSpeakerEnabled
            )
        )
    }

    private func previewControl(
        symbol: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(Palette.previewControl)
        .foregroundStyle(.white)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview {
    NavigationStack {
        NewMeetingView()
    }
}

extension Palette {
    static let previewBackground = Color(red: 31 / 255, green: 33 / 255, blue: 46 / 255)
    static let previewControl = Color(red: 56 / 255, green: 59 / 255, blue: 74 / 255)
    static let previewPrimaryText = Color(red: 204 / 255, green: 207 / 255, blue: 219 / 255)
    static let previewSecondaryText = Color(red: 148 / 255, green: 153 / 255, blue: 173 / 255)
    static let success = Color(red: 36 / 255, green: 186 / 255, blue: 125 / 255)
}
