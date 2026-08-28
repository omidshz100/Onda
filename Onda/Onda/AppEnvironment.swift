import Foundation

struct AppEnvironment {
    let meetingRepository: any MeetingRepository

    @MainActor static let live: AppEnvironment = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 3
        sessionConfiguration.requestCachePolicy = .reloadRevalidatingCacheData

        let apiClient = URLSessionAPIClient(
            baseURL: URL(string: "http://127.0.0.1:8000/")!,
            session: URLSession(configuration: sessionConfiguration)
        )
        let cache = CoreDataMeetingCache(container: PersistenceController.shared.container)

        return AppEnvironment(
            meetingRepository: DefaultMeetingRepository(apiClient: apiClient, cache: cache)
        )
    }()
}
