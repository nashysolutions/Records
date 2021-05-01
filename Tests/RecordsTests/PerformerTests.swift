import CoreData
import XCTest

final class PerformerTests: BaseTests {
    
    func testFetchFirst() {
        let date = Date()
        var performer: Performer!
        performer = Performer(context: container.viewContext)
        performer.firstName = "Bob"
        performer.lastName = "Nash"
        performer.dob = Calendar.current.date(byAdding: .year, value: -1, to: date)!
        let name = "Stacey"
        performer = Performer(context: container.viewContext)
        performer.firstName = name
        performer.lastName = "Nash"
        performer.dob = Calendar.current.date(byAdding: .year, value: -2, to: date)!
        let dob = Calendar.current.date(byAdding: .year, value: -3, to: date)!
        performer = Performer(context: container.viewContext)
        performer.firstName = "Carl"
        performer.lastName = "Nash"
        performer.dob = dob
        let predicate = NSPredicate(format: "dob > %@", dob as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "dob", ascending: true)
        let a: Performer? = try! Performer.fetchFirst(withPredicate: predicate, in: container.viewContext, sortedBy: [sortDescriptor])
        XCTAssert(a?.firstName == name)
    }
    
    func testFetchDateRange1() {
        let date = Date()
        var performer: Performer!
        performer = Performer(context: container.viewContext)
        let name = "Bob"
        performer.firstName = name
        performer.lastName = "Nash"
        let bobsDOB = Calendar.current.date(byAdding: .year, value: -1, to: date)!
        performer.dob = bobsDOB
        performer = Performer(context: container.viewContext)
        performer.firstName = "Stacey"
        performer.lastName = "Nash"
        let statceysDOB = Calendar.current.date(byAdding: .year, value: -2, to: date)!
        performer.dob = statceysDOB
        performer = Performer(context: container.viewContext)
        performer.firstName = "Carl"
        performer.lastName = "Nash"
        let carsDOB = Calendar.current.date(byAdding: .year, value: -3, to: date)!
        performer.dob = carsDOB
        let lower = Calendar.current.date(byAdding: .month, value: -18, to: date)!
        let upper = date
        let a: Performer? = try! Performer.Query(dob: lower...upper).first(in: container.viewContext)
        XCTAssert(a?.firstName == name)
    }
    
    func testFetchDateRange2() {
        let date = Date()
        var performer: Performer!
        performer = Performer(context: container.viewContext)
        performer.firstName = "Bob"
        performer.lastName = "Nash"
        let bobsDOB = Calendar.current.date(byAdding: .year, value: -1, to: date)!
        performer.dob = bobsDOB
        performer = Performer(context: container.viewContext)
        let name = "Stacey"
        performer.firstName = name
        performer.lastName = "Nash"
        let statceysDOB = Calendar.current.date(byAdding: .year, value: -2, to: date)!
        performer.dob = statceysDOB
        performer = Performer(context: container.viewContext)
        performer.firstName = "Carl"
        performer.lastName = "Nash"
        let carsDOB = Calendar.current.date(byAdding: .year, value: -3, to: date)!
        performer.dob = carsDOB
        let lower = Calendar.current.date(byAdding: .month, value: -36, to: date)!
        let upper = Calendar.current.date(byAdding: .month, value: -18, to: date)!
        let a: Performer? = try! Performer.Query(dob: lower...upper).first(in: container.viewContext)
        XCTAssert(a?.firstName == name)
    }
    
    private func createPerfomers(count: Int, inContext context: NSManagedObjectContext) {
        let date = Date()
        for _ in 0..<count {
            let performer = Performer(context: context)
            performer.firstName = "Bob"
            performer.lastName = "Nash"
            performer.dob = date
        }
    }
    
    func testFetchAll1() {
        let count: Int = 3
        createPerfomers(count: count, inContext: container.viewContext)
        let all: [Performer]? = try! Performer.fetchAll(in: container.viewContext)
        let total = all?.count ?? 0
        let message = String(format: "Total is %i not: %i", total, count)
        XCTAssert(total == count, message)
    }
    
    func testFetchAll2() {
        let count: Int = 3
        createPerfomers(count: count, inContext: container.viewContext)
        let query = Performer.Query(
            firstName: .init(candidate: "Bob", match: .exact),
            lastName: .init(candidate: "Nash", match: .exact))
        let all: [Performer]? = try! query.all(in: container.viewContext)
        let total = all?.count ?? 0
        let message = String(format: "Total is %i not: %i", total, count)
        XCTAssert(total == count, message)
    }
    
    func testFetchAll3() {
        let count: Int = 3
        createPerfomers(count: count, inContext: container.viewContext)
        let date = Date()
        let name = "David"
        var performer: Performer!
        performer = Performer(context: container.viewContext)
        performer.firstName = name
        performer.lastName = "Nash"
        performer.dob = date
        let predicate = NSPredicate(format: "firstName == %@", name)
        let all: [Performer]? = try! Performer.fetchAll(withPredicate: predicate, in: container.viewContext)
        let total = all?.count ?? 0
        let message = String(format: "Total is %i not: %i", total, count)
        XCTAssert(total == 1, message)
        performer = all?.first
        XCTAssert(performer.firstName == name)
    }
    
    func testFetchAll4() {
        let count: Int = 1
        createPerfomers(count: count, inContext: container.viewContext)
        
        let performer = Performer(context: container.viewContext)
        performer.firstName = "Dave"
        performer.lastName = "Nash"
        performer.dob = Date()
        
        let query = Performer.Query(
            firstName: .init(candidate: "Da", match: .beginningWith),
            lastName: .init(candidate: "Nash", match: .exact))
        let all: [Performer]? = try! query.all(in: container.viewContext)
        let total = all?.count ?? 0
        let message = String(format: "Total is %i not: %i", total, count)
        XCTAssert(total == count, message)
    }
    
    func testPrimaryKey() throws {
        let date = Date()
        let identifier: Int64 = 2
        let data = JSONEvent(startDate: date, identifier: identifier)
        _ = try data.record(in: container.viewContext) // expectation: create
        _ = try data.record(in: container.viewContext) // expectation: fetch
        let count = try Event.count(in: container.viewContext)
        XCTAssert(count == 1)
    }
}
