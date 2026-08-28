//
//  CallsProfileView.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import SwiftUI
import UIKit

struct CallsProfileView: View {
    @Binding var profile: OndaProfile
    @State private var selectedFilter = CallFilter.recent
    @State private var activeCall: CallRecord?
    @State private var isShowingSettings = false
    @State private var isShowingJoinPrompt = false
    @State private var joinCode = ""
    @State private var notice = ""
    @State private var isShowingNotice = false
    private let calls = CallRecord.samples

    init(profile: Binding<OndaProfile>) {
        _profile = profile

        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Palette.secondaryText)],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Palette.brand)],
            for: .selected
        )
    }

    private var visibleCalls: [CallRecord] {
        switch selectedFilter {
        case .recent:
            calls
        case .missed:
            calls.filter(\.isMissed)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header

                    profileCard
                        .padding(.top, 20)

                    Text("Calls")
                        .font(.title2.bold())
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 36)

                    callFilter
                        .padding(.top, 12)

                    callHistory
                        .padding(.top, 26)

                    quickActions
                        .padding(.top, 38)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
            .background(Palette.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
        .sheet(isPresented: $isShowingSettings) {
            ProfileSettingsView(profile: $profile)
        }
        .fullScreenCover(item: $activeCall) { call in
            LiveMeetingView(meeting: call.meeting)
        }
        .alert("Join a meeting", isPresented: $isShowingJoinPrompt) {
            TextField("Code or link", text: $joinCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Cancel", role: .cancel) {
                joinCode = ""
            }

            Button("Join") {
                joinMeeting()
            }
            .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter the meeting code or invitation link.")
        }
        .alert("Onda", isPresented: $isShowingNotice) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notice)
        }
    }

    private var header: some View {
        HStack {
            Text("Onda")
                .font(.largeTitle.bold())
                .foregroundStyle(Palette.ink)

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body.weight(.medium))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(.white)
            .foregroundStyle(Palette.secondaryText)
            .accessibilityLabel("Profile settings")
        }
        .frame(minHeight: 48)
    }

    private var profileCard: some View {
        Button {
            isShowingSettings = true
        } label: {
            HStack(spacing: 20) {
                AvatarView(initials: profile.initials, style: .primary, size: 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title3.bold())
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)

                    Text(profile.isAvailable ? "Available" : "Do not disturb")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(profile.isAvailable ? Palette.success : Palette.callEnd)

                    Text(profile.email)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens profile settings")
    }

    private var callFilter: some View {
        Picker("Call filter", selection: $selectedFilter) {
            ForEach(CallFilter.allCases) { filter in
                Text(filter.rawValue)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(height: 44)
    }

    private var callHistory: some View {
        LazyVStack(spacing: 12) {
            ForEach(visibleCalls) { call in
                Button {
                    activeCall = call
                } label: {
                    CallHistoryRow(call: call)
                }
                .buttonStyle(.plain)
            }

            if visibleCalls.isEmpty {
                ContentUnavailableView(
                    "No missed calls",
                    systemImage: "phone.badge.checkmark",
                    description: Text("You are all caught up.")
                )
                .frame(minHeight: 152)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedFilter)
    }

    private var quickActions: some View {
        HStack(spacing: 0) {
            NavigationLink {
                NewMeetingView()
            } label: {
                QuickActionLabel(title: "Start a call", symbol: "video.fill")
            }
            .buttonStyle(.plain)

            Button {
                showNotice("Scheduling will be added in the next screen.")
            } label: {
                QuickActionLabel(title: "Schedule", symbol: "calendar")
            }
            .buttonStyle(.plain)

            Button {
                isShowingJoinPrompt = true
            } label: {
                QuickActionLabel(title: "Join", symbol: "link")
            }
            .buttonStyle(.plain)

            Button {
                showNotice("Contacts will be added in a later screen.")
            } label: {
                QuickActionLabel(title: "Contacts", symbol: "person.2.fill")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 86)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func joinMeeting() {
        let trimmedCode = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else { return }

        joinCode = ""
        activeCall = CallRecord(
            name: "Joined meeting",
            detail: trimmedCode,
            initials: "JM",
            direction: .incoming,
            isMissed: false
        )
    }

    private func showNotice(_ message: String) {
        notice = message
        isShowingNotice = true
    }
}

private struct CallHistoryRow: View {
    let call: CallRecord

    var body: some View {
        HStack(spacing: 14) {
            Text(call.initials)
                .font(.callout.bold())
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(call.isMissed ? Palette.callEnd : Palette.brand)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(call.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)

                Text(call.detail)
                    .font(.caption)
                    .foregroundStyle(call.isMissed ? Palette.callEnd : Palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Image(systemName: call.direction.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(call.isMissed ? Palette.callEnd : Palette.brand)
                .frame(width: 24, height: 30)

            Circle()
                .fill(Palette.brand)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(call.name), \(call.detail)")
        .accessibilityHint("Starts a new call")
    }
}

private struct QuickActionLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.brand)
                .frame(height: 24)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .contentShape(Rectangle())
    }
}

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var profile: OndaProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $profile.name)
                        .textContentType(.name)

                    TextField("Email", text: $profile.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }

                Section("Status") {
                    Toggle("Available", isOn: $profile.isAvailable)
                        .tint(Palette.success)
                }
            }
            .navigationTitle("Profile settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .tint(Palette.brand)
        .preferredColorScheme(.light)
    }
}

struct OndaProfile {
    var name: String
    var email: String
    var isAvailable: Bool

    var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    static let sample = OndaProfile(
        name: "Omid Shojaeian",
        email: "omid@onda.app",
        isAvailable: true
    )
}

private enum CallFilter: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case missed = "Missed"

    var id: Self { self }
}

private enum CallDirection {
    case outgoing
    case incoming

    var symbol: String {
        switch self {
        case .outgoing: "arrow.up.right"
        case .incoming: "arrow.down.left"
        }
    }
}

private struct CallRecord: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let initials: String
    let direction: CallDirection
    let isMissed: Bool

    var meeting: MeetingSession {
        MeetingSession(
            title: name,
            participantCount: 2
        )
    }

    static let samples = [
        CallRecord(
            name: "Martina",
            detail: "Today, 10:24 · 18 min",
            initials: "M",
            direction: .outgoing,
            isMissed: false
        ),
        CallRecord(
            name: "Product team",
            detail: "Yesterday · 42 min",
            initials: "P",
            direction: .incoming,
            isMissed: false
        ),
        CallRecord(
            name: "Francesca",
            detail: "Wednesday · Missed",
            initials: "F",
            direction: .incoming,
            isMissed: true
        )
    ]
}

#Preview {
    CallsProfileView(profile: .constant(.sample))
}
