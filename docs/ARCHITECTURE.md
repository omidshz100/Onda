# Onda architecture

## Current vertical slice

```text
HomeView (SwiftUI)
    -> HomeViewModel (MVVM + Combine state)
        -> MeetingRepository protocol
            -> URLSessionAPIClient -> FastAPI /api/v1
            -> CoreDataMeetingCache -> SQLite persistent store
```

The view owns rendering and transient UI state. `HomeViewModel` coordinates loading. `DefaultMeetingRepository` owns the remote-first/offline-fallback policy. DTOs are mapped into `MeetingSession`, keeping transport details out of feature views. Protocol-based dependencies allow deterministic tests without a live server.

## Offline-first policy

1. Request `/api/v1/meetings/upcoming` with URLSession and async/await.
2. Map the versioned API response into domain models.
3. Replace the Core Data meeting cache after a successful response.
4. If networking fails, return cached meetings.
5. If the cache is empty, return a bundled sample so the app remains operable.

## Navigation and data ownership

`MeetingSession` is the typed payload passed from Home, Calls, or New Meeting into Live Meeting. The same instance continues into Participants and Meeting Chat. `ChatConversation` is a typed navigation value whose hash identity is stable by ID.

## Backend contract

FastAPI exposes versioned endpoints under `/api/v1`. Pydantic validates create requests and response models. OpenAPI is generated at `/openapi.json`, and Swagger UI is available at `/docs`.

## Next production slices

These are intentionally not claimed as implemented:

- Authentication and Keychain token storage
- Persistent SQL database and migrations on the backend
- WebSocket-based live participant/chat events
- Call SDK integration and UIKit interoperability where required by the SDK
- Instruments baselines, signposts, and performance budgets
- TestFlight delivery and production observability

Each should be added only when a user-facing feature requires it.
