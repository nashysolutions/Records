import CoreData
import Records
import XCTest

struct Information: Recordable {
    
    let name: String
    let phone: String
    let email: String
    let type: String
    
    var partyType: Party.PartyType {
        return Party.PartyType(rawValue: type)!
    }
    
    var primaryKey: Party.Query {
        return Party.Query(
            email: .init(candidate: email, match: .exact),
            name: .init(candidate: name, match: .exact),
            phone: .init(candidate: phone, match: .exact),
            type: partyType
        )
    }
    
    func update(record: Party) {
        record.email = email
        record.name = name
        record.phone = phone
        record.type_ = partyType
    }
}

final class PartyTests: BaseTests {
    
    func testDefaultValues() {
        let party = Party(context: container.viewContext)
        let message = "Default value missing"
        XCTAssert(party.type_ == .school, message)
    }
    
    func testPrimaryKey() throws {
        let party = Information(name: "DanceSchoolName", phone: "01234567819", email: "dance@school.com", type: "School")
        // expectation: record is created (not fetched)
        let record: Party = try party.record(in: container.viewContext)
        // expectation: record is fetched (not created)
        _ = try party.record(in: container.viewContext)
        // after calling info.record(in:) twice, we should just have one record
        let count = try Party.count(in: container.viewContext)
        // just one so primary key is good
        XCTAssert(count == 1)
        XCTAssertTrue(record.name == "DanceSchoolName")
    }
}
