import CoreData
import Foundation

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "OndaModel")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

final class CoreDataMeetingCache: MeetingCache, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func loadUpcomingMeetings() async throws -> [MeetingSession] {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = NSFetchRequest<NSManagedObject>(entityName: "CachedMeeting")
                    request.sortDescriptors = [NSSortDescriptor(key: "startsAt", ascending: true)]
                    let objects = try context.fetch(request)
                    let meetings = objects.compactMap(Self.makeMeeting(from:))
                    continuation.resume(returning: meetings)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveUpcomingMeetings(_ meetings: [MeetingSession]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedMeeting")
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    try context.execute(deleteRequest)

                    for meeting in meetings {
                        let object = NSEntityDescription.insertNewObject(
                            forEntityName: "CachedMeeting",
                            into: context
                        )
                        object.setValue(meeting.id, forKey: "id")
                        object.setValue(meeting.title, forKey: "title")
                        object.setValue(meeting.code, forKey: "code")
                        object.setValue(meeting.startedAt, forKey: "startsAt")
                        object.setValue(Int64(meeting.participantCount), forKey: "participantCount")
                        object.setValue(meeting.configuration.usesWaitingRoom, forKey: "usesWaitingRoom")
                        object.setValue(meeting.configuration.isMicrophoneEnabled, forKey: "isMicrophoneEnabled")
                        object.setValue(meeting.configuration.isCameraEnabled, forKey: "isCameraEnabled")
                        object.setValue(meeting.configuration.isSpeakerEnabled, forKey: "isSpeakerEnabled")
                    }

                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    nonisolated private static func makeMeeting(from object: NSManagedObject) -> MeetingSession? {
        guard let id = object.value(forKey: "id") as? UUID,
              let title = object.value(forKey: "title") as? String,
              let startsAt = object.value(forKey: "startsAt") as? Date else {
            return nil
        }

        return MeetingSession(
            id: id,
            title: title,
            code: object.value(forKey: "code") as? String,
            startedAt: startsAt,
            participantCount: Int(object.value(forKey: "participantCount") as? Int64 ?? 0),
            configuration: MeetingConfiguration(
                usesWaitingRoom: object.value(forKey: "usesWaitingRoom") as? Bool ?? true,
                isMicrophoneEnabled: object.value(forKey: "isMicrophoneEnabled") as? Bool ?? true,
                isCameraEnabled: object.value(forKey: "isCameraEnabled") as? Bool ?? false,
                isSpeakerEnabled: object.value(forKey: "isSpeakerEnabled") as? Bool ?? true
            )
        )
    }
}
