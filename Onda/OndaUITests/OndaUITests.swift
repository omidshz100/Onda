//
//  OndaUITests.swift
//  OndaUITests
//
//  Created by Omid Shojaeian Zanjani on 28/08/2026.
//

import XCTest

final class OndaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testPrimaryNavigationFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["New meeting"].tap()
        XCTAssertTrue(app.navigationBars["New meeting"].waitForExistence(timeout: 2))

        let startMeeting = app.buttons["Start meeting"]
        if !startMeeting.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        startMeeting.tap()

        let participants = app.buttons["Participants"]
        XCTAssertTrue(participants.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Friday product review"].exists)
        participants.tap()
        XCTAssertTrue(app.navigationBars["Participants"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()

        let meetingChat = app.buttons["Meeting chat"]
        XCTAssertTrue(meetingChat.waitForExistence(timeout: 2))
        meetingChat.tap()
        XCTAssertTrue(app.staticTexts["Meeting chat"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["1 person · Encrypted"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["End call"].tap()

        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Chat"].tap()
        app.staticTexts["Product team"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Product team"].waitForExistence(timeout: 2))
        app.buttons["Start video call"].tap()
        XCTAssertTrue(app.buttons["End call"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Call with Product team"].exists)
        app.buttons["End call"].tap()

        app.tabBars.buttons["Calls"].tap()
        app.staticTexts["Martina"].firstMatch.tap()
        XCTAssertTrue(app.buttons["End call"].waitForExistence(timeout: 2))
        app.buttons["End call"].tap()

        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2))
        app.buttons["Notifications"].tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSecondaryNavigationDestinations() throws {
        let app = XCUIApplication()
        app.launch()

        let recentConversation = app.staticTexts["Francesca"]
        for _ in 0..<3 where !recentConversation.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        recentConversation.tap()
        XCTAssertTrue(app.navigationBars["Francesca"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()

        app.tabBars.buttons["Calls"].tap()
        let startCall = app.buttons["Start a call"]
        for _ in 0..<3 where !startCall.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        startCall.tap()
        XCTAssertTrue(app.navigationBars["New meeting"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()

        app.tabBars.buttons["Chat"].tap()
        app.buttons["New conversation"].tap()
        XCTAssertTrue(app.navigationBars["New conversation"].waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()

        app.tabBars.buttons["You"].tap()
        for title in ["Notifications", "Audio & video", "Privacy & security"] {
            app.buttons[title].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 2))
            app.navigationBars.buttons.firstMatch.tap()
        }

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Profile settings"].waitForExistence(timeout: 2))
        app.buttons["Close"].tap()
    }

    @MainActor
    func testCaptureRepositoryScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 3))
        captureScreenshot(named: "01-home", app: app)

        app.buttons["New meeting"].tap()
        XCTAssertTrue(app.navigationBars["New meeting"].waitForExistence(timeout: 2))
        captureScreenshot(named: "02-new-meeting", app: app)

        let startMeeting = app.buttons["Start meeting"]
        if !startMeeting.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        startMeeting.tap()
        XCTAssertTrue(app.buttons["Participants"].waitForExistence(timeout: 3))
        captureScreenshot(named: "03-live-meeting", app: app)

        app.buttons["Participants"].tap()
        XCTAssertTrue(app.navigationBars["Participants"].waitForExistence(timeout: 2))
        captureScreenshot(named: "04-participants", app: app)
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["Meeting chat"].tap()
        XCTAssertTrue(app.staticTexts["Meeting chat"].waitForExistence(timeout: 2))
        captureScreenshot(named: "05-meeting-chat", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["End call"].tap()
        app.navigationBars.buttons.firstMatch.tap()

        app.tabBars.buttons["Calls"].tap()
        XCTAssertTrue(app.staticTexts["Calls"].waitForExistence(timeout: 2))
        captureScreenshot(named: "06-calls", app: app)

        app.tabBars.buttons["Chat"].tap()
        XCTAssertTrue(app.staticTexts["Chat"].waitForExistence(timeout: 2))
        captureScreenshot(named: "07-chat-list", app: app)

        app.tabBars.buttons["You"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2))
        captureScreenshot(named: "08-profile", app: app)
    }

    private func captureScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
