import Foundation

nonisolated enum MeetingDataSource: Equatable, Sendable {
    case remote
    case cache
    case bundledFallback
}

nonisolated struct MeetingFeed: Equatable, Sendable {
    let meetings: [MeetingSession]
    let source: MeetingDataSource
}

@MainActor
protocol MeetingRepository: Sendable {
    func fetchUpcomingMeetings() async -> MeetingFeed
}

nonisolated protocol MeetingCache: Sendable {
    func loadUpcomingMeetings() async throws -> [MeetingSession]
    func saveUpcomingMeetings(_ meetings: [MeetingSession]) async throws
}

nonisolated struct MeetingDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let code: String?
    let startsAt: Date
    let participantCount: Int
    let configuration: MeetingConfigurationDTO

    var domainModel: MeetingSession {
        MeetingSession(
            id: id,
            title: title,
            code: code,
            startedAt: startsAt,
            participantCount: participantCount,
            configuration: configuration.domainModel
        )
    }
}

nonisolated struct MeetingConfigurationDTO: Decodable, Sendable {
    let usesWaitingRoom: Bool
    let isMicrophoneEnabled: Bool
    let isCameraEnabled: Bool
    let isSpeakerEnabled: Bool

    var domainModel: MeetingConfiguration {
        MeetingConfiguration(
            usesWaitingRoom: usesWaitingRoom,
            isMicrophoneEnabled: isMicrophoneEnabled,
            isCameraEnabled: isCameraEnabled,
            isSpeakerEnabled: isSpeakerEnabled
        )
    }
}

final class DefaultMeetingRepository: MeetingRepository, @unchecked Sendable {
    private let apiClient: any APIClientProtocol
    private let cache: any MeetingCache

    init(apiClient: any APIClientProtocol, cache: any MeetingCache) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func fetchUpcomingMeetings() async -> MeetingFeed {
        do {
            let response = try await apiClient.send(
                APIEndpoint(path: "api/v1/meetings/upcoming"),
                as: [MeetingDTO].self
            )
            let meetings = response.map { $0.domainModel }
            try? await cache.saveUpcomingMeetings(meetings)
            return MeetingFeed(meetings: meetings, source: .remote)
        } catch {
            if let cachedMeetings = try? await cache.loadUpcomingMeetings(),
               !cachedMeetings.isEmpty {
                return MeetingFeed(meetings: cachedMeetings, source: .cache)
            }

            return MeetingFeed(meetings: [.upcomingDesignSync], source: .bundledFallback)
        }
    }
}
