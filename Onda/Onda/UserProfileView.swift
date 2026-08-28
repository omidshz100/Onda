//
//  UserProfileView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI

struct UserProfileView: View {
    @Binding var profile: OndaProfile

    @State private var isEditingProfile = false
    @State private var isConfirmingSignOut = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    statsCard
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                settingsSection

                Section {
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 28)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.callEnd)
                    .listRowBackground(Palette.dangerSoft)
                    .accessibilityHint("Signs out of your Onda account")
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(24)
            .scrollContentBackground(.hidden)
            .background(Palette.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        isEditingProfile = true
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .sheet(isPresented: $isEditingProfile) {
            ProfileSettingsView(profile: $profile)
        }
        .alert("Sign out of Onda?", isPresented: $isConfirmingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", role: .destructive) {
                profile.isAvailable = false
            }
        } message: {
            Text("You will need to sign in again to join meetings from this device.")
        }
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            AvatarView(initials: profile.initials, style: .primary, size: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.name)
                    .font(.title3.bold())
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(profile.email)
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Circle()
                        .fill(profile.isAvailable ? Palette.success : Palette.callEnd)
                        .frame(width: 7, height: 7)

                    Text(profile.isAvailable ? "Available" : "Do not disturb")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(profile.isAvailable ? Palette.success : Palette.callEnd)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(profile.isAvailable ? Palette.successSoft : Palette.dangerSoft)
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 156, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name), \(profile.email), \(profile.isAvailable ? "Available" : "Do not disturb")")
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            ProfileStat(value: "24", label: "Calls")

            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(width: 1, height: 34)

            ProfileStat(value: "8h 42m", label: "Total time")

            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(width: 1, height: 34)

            ProfileStat(value: "12", label: "Contacts")
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var settingsSection: some View {
        Section {
            NavigationLink {
                NotificationSettingsView()
            } label: {
                ProfileSettingRow(title: "Notifications", systemImage: "bell.fill")
            }

            NavigationLink {
                AudioVideoSettingsView()
            } label: {
                ProfileSettingRow(title: "Audio & video", systemImage: "video.fill")
            }

            NavigationLink {
                PrivacySecurityView()
            } label: {
                ProfileSettingRow(title: "Privacy & security", systemImage: "lock.fill")
            }
        } header: {
            Text("Settings")
                .font(.title3.bold())
                .foregroundStyle(Palette.ink)
                .textCase(nil)
        }
    }
}

private struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Palette.ink)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ProfileSettingRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Palette.brand)
                .frame(width: 36, height: 36)
                .background(Palette.brandSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
        }
        .frame(minHeight: 46)
    }
}

private struct NotificationSettingsView: View {
    @State private var incomingCalls = true
    @State private var meetingReminders = true
    @State private var messages = true

    var body: some View {
        Form {
            Section("Notify me about") {
                Toggle("Incoming calls", isOn: $incomingCalls)
                Toggle("Meeting reminders", isOn: $meetingReminders)
                Toggle("New messages", isOn: $messages)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AudioVideoSettingsView: View {
    @State private var microphoneOn = true
    @State private var cameraOn = true
    @State private var noiseReduction = true

    var body: some View {
        Form {
            Section("Meeting defaults") {
                Toggle("Microphone on", isOn: $microphoneOn)
                Toggle("Camera on", isOn: $cameraOn)
                Toggle("Noise reduction", isOn: $noiseReduction)
            }
        }
        .navigationTitle("Audio & video")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacySecurityView: View {
    @State private var allowUnknownCallers = false
    @State private var readReceipts = true

    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Allow unknown callers", isOn: $allowUnknownCallers)
                Toggle("Send read receipts", isOn: $readReceipts)
            }

            Section("Security") {
                Label("End-to-end encryption", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(Palette.success)
            }
        }
        .navigationTitle("Privacy & security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Palette {
    static let dangerSoft = Color(red: 1, green: 240 / 255, blue: 240 / 255)
    static let successSoft = Color(red: 232 / 255, green: 250 / 255, blue: 240 / 255)
}

#Preview {
    UserProfileView(profile: .constant(.sample))
}
