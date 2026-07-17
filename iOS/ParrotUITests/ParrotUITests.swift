import XCTest

final class ParrotUITests: XCTestCase {
    func testLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
    }
}
