import CoreData
import XCTest

final class PerformanceTests: BaseTests {
    
    func testDefaultValues() {
        let performance = Performance(context: container.viewContext)
        let message = "Default value missing"
        XCTAssert(performance.ability_ == .newcomer, message)
        XCTAssert(performance.group_ == .solo, message)
    }
}
