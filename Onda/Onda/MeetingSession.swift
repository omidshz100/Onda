//
//  MeetingSession.swift
//  Onda
//
//  Created by Codex on 28/08/2026.
//

import Foundation

nonisolated struct MeetingSession: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let code: String?
    let startedAt: Date
    let participantCount: Int
    let configuration: MeetingConfiguration

    init(
        id: UUID = UUID(),
        title: String,
        code: String? = nil,
        startedAt: Date = .now,
        participantCount: Int = 1,
        configuration: MeetingConfiguration = .default
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.startedAt = startedAt
        self.participantCount = participantCount
        self.configuration = configuration
    }

    static let designSync = MeetingSession(
        title: "Design sync",
        code: "design-sync",
        startedAt: Date().addingTimeInterval(-(42 * 60 + 18)),
        participantCount: 4
    )

    static let upcomingDesignSync = MeetingSession(
        title: "Design sync",
        code: "design-sync",
        startedAt: Date().addingTimeInterval(2 * 60 * 60),
        participantCount: 4
    )

    var participantSummary: String {
        "\(participantCount) \(participantCount == 1 ? "participant" : "participants")"
    }

    var peopleSummary: String {
        "\(participantCount) \(participantCount == 1 ? "person" : "people")"
    }
}

nonisolated struct MeetingConfiguration: Hashable, Sendable {
    let usesWaitingRoom: Bool
    let isMicrophoneEnabled: Bool
    let isCameraEnabled: Bool
    let isSpeakerEnabled: Bool

    static let `default` = MeetingConfiguration(
        usesWaitingRoom: true,
        isMicrophoneEnabled: true,
        isCameraEnabled: false,
        isSpeakerEnabled: true
    )
}
