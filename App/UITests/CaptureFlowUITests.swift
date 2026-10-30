import XCTest

/// FR-1…FR-6 capture flow. Runs against fake audio and speech (`-uitest`) so it needs no microphone.
/// Action Button, real microphone and haptics are verified on a physical iPhone (see docs/gate-tests.md).
final class CaptureFlowUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"] + extra
        app.launch()
        return app
    }

    func testSpeakStopAndFindCardInInbox() {
        let app = launch()
        app.buttons["orbButton"].tap()
        XCTAssertTrue(app.otherElements["captureScreen"].waitForExistence(timeout: 3))

        let transcript = app.staticTexts["liveTranscript"]
        XCTAssertTrue(transcript.waitForExistence(timeout: 3))
        let appeared = NSPredicate(format: "value CONTAINS 'email Alice'")
        expectation(for: appeared, evaluatedWith: transcript)
        waitForExpectations(timeout: 5)

        app.buttons["stopCapture"].tap()
        let card = app.descendants(matching: .any).matching(identifier: "thoughtCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "A card should be waiting in the Inbox right after stop")
        XCTAssertTrue(card.label.contains("Remember to email Alice"), "Title falls back to the first line while processing")
    }

    func testCaptureStartsImmediatelyWhenLaunchedFromIntent() {
        let app = launch(["-startCapture"])
        XCTAssertTrue(app.otherElements["captureScreen"].waitForExistence(timeout: 2), "No menu or splash before recording")
    }

    func testTypedFallbackEntersSamePipeline() {
        let app = launch()
        app.buttons["orbButton"].tap()
        app.buttons["typeInstead"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        editor.typeText("Buy oat milk")
        app.buttons["saveTyped"].tap()
        let card = app.descendants(matching: .any).matching(identifier: "thoughtCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.label.contains("Buy oat milk"))
    }

    func testSwipeToArchiveOffersUndo() {
        let app = launch()
        app.buttons["orbButton"].tap()
        app.buttons["typeInstead"].tap()
        app.textViews.firstMatch.typeText("Archive me")
        app.buttons["saveTyped"].tap()
        let card = app.descendants(matching: .any).matching(identifier: "thoughtCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.swipeLeft()
        app.buttons["Archive"].tap()
        XCTAssertTrue(app.buttons["undoButton"].waitForExistence(timeout: 2))
        app.buttons["undoButton"].tap()
        XCTAssertTrue(card.waitForExistence(timeout: 2))
    }
}
