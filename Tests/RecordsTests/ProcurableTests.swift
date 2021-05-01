import CoreData
import XCTest
import Records

final class ProcurableTests: BaseTests {
    
    func testEvent() throws {
        // Local fetch should show empty table
        let initialCount = try Event.count(in: context)
        XCTAssertEqual(initialCount, 0)
        
        // Fetch events and store
        var events: [Event]?
        try JSONEvent.archive(in: context) { records in
            events = records
        }
        
        // 6 Records fetched
        let unwrapped = try XCTUnwrap(events)
        XCTAssertEqual(unwrapped.count, 6)
        
        // 6 Records saved
        let finalCount = try Event.count(in: context)
        XCTAssertEqual(finalCount, 6)
    }
}

extension JSONEvent: Procurable {
    
    static var json: URL {
        Bundle.module.url(forResource: "Events", withExtension: "json")!
    }
    
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(eventDateFormatter)
        return decoder
    }
    
    private static var eventDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/M/yyyy"
        return dateFormatter
    }()
}
