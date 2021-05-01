@testable import Records
import CoreData
import XCTest

final class AggregateTests: BaseTests {
    
    func testAggregate1() {
        let performer = Performer(context: container.viewContext)
        let records: Set<Performer> = Set([performer])
        let value = Aggregate<Performer>.Operator.someMatching
        let aggregate = Aggregate<Performer>(value, records: records)
        let message1 = "Unexpected value. Expecting: \(value), Actual: \(aggregate.operation)"
        XCTAssert(aggregate.operation == .someMatching, message1)
        let message2 = "Unexpected value. Expecting: \(records), Actual: \(aggregate.records)"
        XCTAssert(aggregate.records == records, message2)
    }
    
    func testAggregate2() {
        let performer = Performer(context: container.viewContext)
        let records = Set([performer])
        let aggregate = Aggregate<Performer>(.noneMatching, records: records)
        let attributeName = "someAttributeName"
        let value = aggregate.predicate(attributeName)
        let predicate = NSPredicate(format: "SUBQUERY(\(attributeName), $p, $p in %@).@count == 0", records)
        let valueDescription = String(describing: value)
        let predicateDescription = String(describing: predicate)
        let message1 = "Unexpected value. Expecting: \(valueDescription), Actual: \(predicateDescription)"
        XCTAssert(value == predicate, message1)
    }
    
    func testAggregate3() {
        let performer = Performer(context: container.viewContext)
        let records = Set([performer])
        let aggregate = Aggregate<Performer>(.someMatching, records: records)
        let attributeName = "someAttributeName"
        let value = aggregate.predicate(attributeName)
        let predicate = NSPredicate(format: "ANY " + attributeName + " " + "IN" + " " + "%@", records)
        let valueDescription = String(describing: value)
        let predicateDescription = String(describing: predicate)
        let message1 = "Unexpected value. Expecting: \(valueDescription), Actual: \(predicateDescription)"
        XCTAssert(value == predicate, message1)
    }
    
    func testAggregate4() {
        let performer = Performer(context: container.viewContext)
        let records = Set([performer])
        let aggregate = Aggregate<Performer>(.allMatching, records: records)
        let attributeName = "someAttributeName"
        let value = aggregate.predicate(attributeName)
        let predicate = NSPredicate(format: "SUBQUERY(\(attributeName), $p, $p in %@).@count = %d", records, records.count)
        let valueDescription = String(describing: value)
        let predicateDescription = String(describing: predicate)
        let message1 = "Unexpected value. Expecting: \(valueDescription), Actual: \(predicateDescription)"
        XCTAssert(value == predicate, message1)
    }
}
