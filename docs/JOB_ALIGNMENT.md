# Job-alignment matrix

This document separates implemented evidence from future work so resume claims remain accurate.

| Requirement | Implemented evidence in Onda | Status |
|---|---|---|
| Swift and scalable MVVM | `HomeViewModel`, repository protocol, domain/DTO separation | Implemented |
| SwiftUI and Combine | SwiftUI screens plus `ObservableObject`/`@Published` state | Implemented |
| Core Data | Background-context offline meeting cache and in-memory persistence test | Implemented |
| URLSession and REST | Generic URLSession client, typed HTTP errors, async/await DTO decoding | Implemented |
| REST API / FastAPI | `/api/v1/meetings` service, Pydantic validation, OpenAPI/Swagger | Implemented |
| Unit and UI testing | XCTest repository/contract/Core Data tests and XCUITest navigation flows | Implemented |
| CI/CD | GitHub Actions jobs for iOS and Python tests | Implemented (CI); deployment is not yet configured |
| API versioning | `/api/v1` routing | Implemented |
| UIKit / Auto Layout | No feature currently needs imperative UIKit layout | Not yet - intentionally omitted |
| Third-party SDKs | No production call or analytics provider selected | Not yet |
| Authentication / authorization | UI profile exists, but no server identity flow | Not yet |
| SQL/NoSQL backend storage | Backend currently uses a concurrency-safe in-memory store | Not yet |
| Real-time data pipeline | Meeting UI exists, but no WebSocket event transport | Not yet |
| Instruments / LLDB profiling | No recorded performance baseline yet | Not yet |
| App Store / TestFlight | No distribution pipeline or release metadata yet | Not yet |
| Generative AI | Not added because Onda has no validated AI user story yet | Not yet |

## Resume-safe summary

Built an offline-first SwiftUI meeting application using MVVM, Combine, protocol-based dependency injection, URLSession/async-await REST integration, and Core Data caching; developed a versioned FastAPI/Pydantic service with OpenAPI documentation; and added XCTest, XCUITest, and GitHub Actions CI coverage.
