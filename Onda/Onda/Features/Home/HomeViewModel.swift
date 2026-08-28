import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadingState: Equatable {
        case idle
        case loading
        case loaded(MeetingDataSource)
    }

    @Published private(set) var upcomingMeetings: [MeetingSession]
    @Published private(set) var loadingState: LoadingState = .idle

    private let repository: any MeetingRepository

    init(
        repository: any MeetingRepository,
        initialMeetings: [MeetingSession]? = nil
    ) {
        self.repository = repository
        upcomingMeetings = initialMeetings ?? [.upcomingDesignSync]
    }

    var featuredMeeting: MeetingSession {
        upcomingMeetings.first ?? .upcomingDesignSync
    }

    func loadUpcomingMeetings() async {
        guard loadingState != .loading else { return }

        loadingState = .loading
        let feed = await repository.fetchUpcomingMeetings()
        upcomingMeetings = feed.meetings
        loadingState = .loaded(feed.source)
    }
}
