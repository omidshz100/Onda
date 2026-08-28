//
//  OndaTests.swift
//  OndaTests
//
//  Created by Omid Shojaeian Zanjani on 28/08/2026.
//

import XCTest
@testable import Onda

@MainActor
final class OndaTests: XCTestCase {
    func testHomeViewModelLoadsRepositoryFeed() async {
        let expectedMeeting = MeetingSession(
            id: UUID(uuidString: "8CDA88F8-C5C7-41A7-B956-7A2B7A96950F")!,
            title: "Architecture review",
            startedAt: Date(timeIntervalSince1970: 2_000_000_000),
            participantCount: 3
        )
        let repository = StubMeetingRepository(
            feed: MeetingFeed(meetings: [expectedMeeting], source: .remote)
        )
        let viewModel = HomeViewModel(repository: repository, initialMeetings: [])

        await viewModel.loadUpcomingMeetings()

        XCTAssertEqual(viewModel.upcomingMeetings, [expectedMeeting])
        XCTAssertEqual(viewModel.loadingState, .loaded(.remote))
    }

    func testMeetingDTOUsesTheVersionedAPIContract() throws {
        let json = """
        [{
          "id": "ea2abf7e-02b1-4c2a-bd58-4b8a697da2f4",
          "title": "Design sync",
          "code": "design-sync",
          "starts_at": "2030-01-01T12:00:00Z",
          "participant_count": 4,
          "configuration": {
            "uses_waiting_room": true,
            "is_microphone_enabled": false,
            "is_camera_enabled": true,
            "is_speaker_enabled": true
          }
        }]
        """.data(using: .utf8)!

        let result = try URLSessionAPIClient.makeDecoder().decode([MeetingDTO].self, from: json)

        XCTAssertEqual(result.first?.domainModel.title, "Design sync")
        XCTAssertEqual(result.first?.domainModel.participantCount, 4)
        XCTAssertEqual(result.first?.domainModel.configuration.isCameraEnabled, true)
    }

    func testCoreDataMeetingCacheRoundTrip() async throws {
        let persistence = PersistenceController(inMemory: true)
        let cache = CoreDataMeetingCache(container: persistence.container)
        let expectedMeeting = MeetingSession(
            id: UUID(uuidString: "AFA3498F-3CEE-47CD-A366-E6B55BB29FD0")!,
            title: "Offline meeting",
            code: "offline-meeting",
            startedAt: Date(timeIntervalSince1970: 2_100_000_000),
            participantCount: 2,
            configuration: MeetingConfiguration(
                usesWaitingRoom: false,
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                isSpeakerEnabled: true
            )
        )

        try await cache.saveUpcomingMeetings([expectedMeeting])
        let cachedMeetings = try await cache.loadUpcomingMeetings()

        XCTAssertEqual(cachedMeetings, [expectedMeeting])
    }

    func testRepositoryCachesRemoteResponse() async throws {
        let apiClient = StubAPIClient(data: Self.meetingResponseData)
        let cache = InMemoryMeetingCache()
        let repository = DefaultMeetingRepository(apiClient: apiClient, cache: cache)

        let feed = await repository.fetchUpcomingMeetings()

        XCTAssertEqual(feed.source, .remote)
        XCTAssertEqual(feed.meetings.first?.title, "Design sync")
        let cachedMeetings = try await cache.loadUpcomingMeetings()
        XCTAssertEqual(cachedMeetings, feed.meetings)
    }

    func testRepositoryFallsBackToCacheWhenOffline() async throws {
        let cachedMeeting = MeetingSession(
            title: "Cached stand-up",
            startedAt: Date(timeIntervalSince1970: 2_200_000_000),
            participantCount: 5
        )
        let apiClient = StubAPIClient(error: URLError(.notConnectedToInternet))
        let cache = InMemoryMeetingCache(meetings: [cachedMeeting])
        let repository = DefaultMeetingRepository(apiClient: apiClient, cache: cache)

        let feed = await repository.fetchUpcomingMeetings()

        XCTAssertEqual(feed.source, .cache)
        XCTAssertEqual(feed.meetings, [cachedMeeting])
    }

    private static let meetingResponseData = """
    [{
      "id": "ea2abf7e-02b1-4c2a-bd58-4b8a697da2f4",
      "title": "Design sync",
      "code": "design-sync",
      "starts_at": "2030-01-01T12:00:00Z",
      "participant_count": 4,
      "configuration": {
        "uses_waiting_room": true,
        "is_microphone_enabled": true,
        "is_camera_enabled": false,
        "is_speaker_enabled": true
      }
    }]
    """.data(using: .utf8)!
}

private final class StubMeetingRepository: MeetingRepository, @unchecked Sendable {
    private let feed: MeetingFeed

    init(feed: MeetingFeed) {
        self.feed = feed
    }

    func fetchUpcomingMeetings() async -> MeetingFeed {
        feed
    }
}

private final class StubAPIClient: APIClientProtocol, @unchecked Sendable {
    private let data: Data?
    private let error: Error?

    init(data: Data) {
        self.data = data
        error = nil
    }

    init(error: Error) {
        data = nil
        self.error = error
    }

    func send<Response: Decodable>(
        _ endpoint: APIEndpoint,
        as responseType: Response.Type
    ) async throws -> Response {
        if let error {
            throw error
        }
        return try URLSessionAPIClient.makeDecoder().decode(Response.self, from: data ?? Data())
    }
}

private actor InMemoryMeetingCache: MeetingCache {
    private var meetings: [MeetingSession]

    init(meetings: [MeetingSession] = []) {
        self.meetings = meetings
    }

    func loadUpcomingMeetings() async throws -> [MeetingSession] {
        meetings
    }

    func saveUpcomingMeetings(_ meetings: [MeetingSession]) async throws {
        self.meetings = meetings
    }
}
