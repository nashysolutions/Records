import Records
import CoreData
import XCTest

final class QueryTests: BaseTests {
    
    override func setUp() {
        super.setUp()
        try! DataBuilder(context: container.viewContext).populateDatabase()
    }
    
    func testEventCount() throws {
        let count = try Event.count(in: container.viewContext)
        let records = try Event.fetchAll(in: container.viewContext)
        XCTAssertTrue(records.count == 6, "Expecting 6. Actual \(records.count).")
        XCTAssertTrue(records.count == count)
    }
    
    func testPerformerCount() throws {
        let count = try Performer.count(in: container.viewContext)
        let records = try Performer.fetchAll(in: container.viewContext)
        XCTAssertTrue(records.count == 29, "Expecting 29. Actual \(records.count).")
        XCTAssertTrue(records.count == count)
    }
    
    func testPerformanceCount() throws {
        let count = try Performance.count(in: container.viewContext)
        let records = try Performance.fetchAll(in: container.viewContext)
        XCTAssertTrue(records.count == 23, "Expecting 23. Actual \(records.count).")
        XCTAssertTrue(records.count == count)
    }
    
    func testFetchLimit() throws {
        let records = try Performance.fetchAll(fetchLimit: 8, in: container.viewContext)
        XCTAssertTrue(records.count == 8, "Expecting 8. Actual \(records.count).")
    }
    
    func testSortOrder() throws {
        let sort = NSSortDescriptor(key: "firstName", ascending: true)
        let records = try Performer.fetchAll(withSort: [sort], in: container.viewContext)
        let record = records.first
        XCTAssert(record!.firstName == "Angel")
    }
    
    func testSomeMatching() throws {
        guard let p1 = try Performer.Query(
            firstName: .init(candidate: "Angel", match: .exact),
            lastName: .init(candidate: "Jones", match: .exact)).first(in: container.viewContext) else {
            XCTFail("Performer not found")
            return
        }
        guard let p2 = try Performer.Query(
            firstName: .init(candidate: "Ashton", match: .exact),
            lastName: .init(candidate: "Longworth", match: .exact)).first(in: container.viewContext)  else {
            XCTFail("Performer not found")
            return
        }
        let pred = Aggregate<Performer>(.someMatching, records: Set([p1,p2]))
        let query = Performance.Query(performers: pred)
        let performances: [Performance] = try! query.all(in: container.viewContext)
        XCTAssert(performances.count == 4)
        performances.forEach { (performance) in
            XCTAssert(performance.performers.contains(p1) || performance.performers.contains(p2))
        }
    }
    
    func testAllMatching() {
        guard let p1 = try! Performer.Query(
            firstName: .init(candidate: "Angel", match: .exact),
            lastName: .init(candidate: "Jones", match: .exact)).first(in: container.viewContext) else {
            XCTFail("Performer not found")
            return
        }
        guard let p2 = try! Performer.Query(
            firstName: .init(candidate: "Ashton", match: .exact),
            lastName: .init(candidate: "Longworth", match: .exact)).first(in: container.viewContext)  else {
            XCTFail("Performer not found")
            return
        }
        let pred = Aggregate<Performer>(.allMatching, records: Set([p1,p2]))
        let query = Performance.Query(performers: pred)
        let performances: [Performance] = try! query.all(in: container.viewContext)
        XCTAssert(performances.count == 2)
        performances.forEach { (performance) in
            XCTAssert(performance.performers.contains(p1) && performance.performers.contains(p2))
        }
    }
    
    func testNoneMatching() {
        guard let p1 = try! Performer.Query(
            firstName: .init(candidate: "Angel", match: .exact),
            lastName: .init(candidate: "Jones", match: .exact)).first(in: container.viewContext) else {
            XCTFail("Performer not found")
            return
        }
        guard let p2 = try! Performer.Query(
            firstName: .init(candidate: "Ashton", match: .exact),
            lastName: .init(candidate: "Longworth", match: .exact)).first(in: container.viewContext)  else {
            XCTFail("Performer not found")
            return
        }
        let pred = Aggregate<Performer>(.noneMatching, records: Set([p1,p2]))
        let query = Performance.Query(performers: pred)
        let performances: [Performance] = try! query.all(in: container.viewContext)
        XCTAssert(performances.count == 19)
        performances.forEach { (performance) in
            XCTAssert(!performance.performers.contains(p1) || !performance.performers.contains(p2))
        }
    }
    
    func testCreateEventRecord() throws {
        let date = Date()
        let identifier: Int64 = 2
        let data = JSONEvent(startDate: date, identifier: identifier)
        let record = try data.record(in: container.viewContext)
        XCTAssertTrue(record.startDate == date)
    }
    
    func testCreatePerformerAndPartyRecords() throws {
        let firstName = "Rob"
        let lastName = "Nash"
        let dob = Date()
        let performerData = JSONPerformer(firstName: firstName, lastName: lastName, dob: dob)
        let parent = "Rob Nash"
        let phone = "01928374892"
        let email = "bob@nash.com"
        let type = "Independent"
        let partyData = JSONParty(name: parent, phone: phone, email: email, type: type)
        let party = try partyData.record(in: container.viewContext)
        let export = performerData.export(withParty: party)
        let performer = try export.record(in: container.viewContext)
        XCTAssertTrue(performer.firstName == firstName)
        XCTAssertTrue(performer.lastName == lastName)
        XCTAssertTrue(performer.dob == dob)
        XCTAssertTrue(performer.party == party)
        XCTAssertTrue(party.name == parent)
        XCTAssertTrue(party.phone == phone)
        XCTAssertTrue(party.email == email)
        XCTAssertTrue(party.type_.rawValue == type)
    }
    
    func testCreatePerformanceRecord() throws {
        let parent = "Rob Nash"
        let phone = "01928374892"
        let email = "bob@nash.com"
        let type = "Independent"
        let partyData = JSONParty(name: parent, phone: phone, email: email, type: type)
        let party = try partyData.record(in: container.viewContext)
        let date = Date()
        let identifier: Int64 = 2
        let eventData = JSONEvent(startDate: date, identifier: identifier)
        let event = try eventData.record(in: container.viewContext)
        let firstName = "Rob"
        let lastName = "Nash"
        let dob = Date()
        let performerData = JSONPerformer(firstName: firstName, lastName: lastName, dob: dob)
        let performers = [performerData]
        let ability = "Newcomer"
        let group = "Solo"
        let performanceData = JSONPerformance(ability: ability, group: group, performers: performers)
        let export = try performanceData.export(withEvent: event, withParty: party, withContext: container.viewContext)
        let performance = try export.record(in: container.viewContext)
        XCTAssertTrue(performance.ability_.rawValue == ability)
        XCTAssertTrue(performance.group_.rawValue == group)
        let performer = performance.performers.first
        XCTAssertNotNil(performer)
        XCTAssertTrue(performer!.firstName == firstName)
        XCTAssertTrue(performer!.lastName == lastName)
        XCTAssertTrue(performer!.dob == dob)
        XCTAssertTrue(performer!.party == party)
        XCTAssertTrue(performance.event == event)
        XCTAssertTrue(party.email == email)
        XCTAssertTrue(party.phone == phone)
        XCTAssertTrue(party.name == parent)
        XCTAssertTrue(party.type_.rawValue == type)
        XCTAssertTrue(event.startDate == date)
    }
}
