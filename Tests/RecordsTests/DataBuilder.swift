@testable import Records
import CoreData

struct DataBuilder {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func populateDatabase() throws {
        let events: [Event] = try unpackEvents().map {
            return try $0.record(in: context)
        }
        let parties: [Party] = try unpackParties().map {
            return try $0.record(in: context)
        }
        let _: [Performance] = try unpackPerformances().map {
            let event = events.first!
            let party = parties.first!
            let export = try $0.export(withEvent: event, withParty: party, withContext: context)
            return try export.record(in: context)
        }
    }
    
    private func unpackEvents() throws -> [JSONEvent] {
        let data = try contentsOf(resource: "Events", extension: "json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(eventDateFormatter)
        return try decoder.decode([JSONEvent].self, from: data)
    }
    
    private let eventDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/M/yyyy"
        return dateFormatter
    }()
    
    private func unpackParties() throws -> [JSONParty] {
        let data = try contentsOf(resource: "Parties", extension: "json")
        let decoder = JSONDecoder()
        return try decoder.decode([JSONParty].self, from: data)
    }
    
    private func unpackPerformances() throws -> [JSONPerformance] {
        let data = try contentsOf(resource: "Performances", extension: "json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dobDateFormatter)
        return try decoder.decode([JSONPerformance].self, from: data)
    }
    
    private let dobDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d/M/yyyy"
        return dateFormatter
    }()
    
    private func contentsOf(resource r: String, extension e: String) throws -> Data {
        let bundle = Bundle.module
        let url = bundle.url(forResource: r, withExtension: e)!
        return try String(contentsOf: url).data(using: .utf8)!
    }
}

struct JSONParty: Decodable, Recordable {
    let name: String
    let phone: String
    let email: String
    let type: String
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case phone = "Phone"
        case email = "Email"
        case type = "Type"
    }
    var partyType: Party.PartyType {
        return Party.PartyType(rawValue: type)!
    }
    var primaryKey: Party.Query {
        return Party.Query(
            email: .init(candidate: email, match: .exact),
            name: .init(candidate: name, match: .exact),
            phone: .init(candidate: phone, match: .exact),
            type: partyType)
    }
    func update(record: Party) {
        record.email = email
        record.name = name
        record.phone = phone
        record.type_ = partyType
    }
}

struct JSONEvent: Decodable, Recordable {
    let startDate: Date
    let identifier: Int64
    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case startDate = "StartDate"
    }
    var primaryKey: Event.Query {
        Event.Query(identifier: identifier)
    }
    func update(record: Event) {
        record.identifier = identifier
        record.startDate = startDate
    }
}

struct JSONPerformer: Decodable {
    struct Export: Recordable {
        let firstName: String
        let lastName: String
        let dob: Date
        let party: Party
        /// There may be performers with identical details between parties and they may be the same person.
        /// Performers may change parties over time and we wouldn't know.
        /// Or performers may have the same details by coinsidence.
        /// So have decided to create a single record per performer per party.
        var primaryKey: Performer.Query {
            let lower = dob.oneDayEarlier
            let upper = dob.oneDayLater
            return Performer.Query(
                dob: lower...upper,
                firstName: .init(candidate: firstName, match: .exact),
                lastName: .init(candidate: lastName, match: .exact),
                party: party)
        }
        func update(record: Performer) {
            record.party = party
            record.dob = dob
            record.firstName = firstName
            record.lastName = lastName
        }
    }
    let firstName: String
    let lastName: String
    let dob: Date
    enum CodingKeys: String, CodingKey {
        case firstName = "First Name"
        case lastName = "Last Name"
        case dob = "D.O.B"
    }
    func export(withParty party: Party) -> Export {
        return Export(firstName: firstName, lastName: lastName, dob: dob, party: party)
    }
}

struct JSONPerformance: Decodable {
    struct Export: Recordable {
        let ability: Performance.Ability
        let group: Performance.Group
        let performers: Set<Performer>
        let event: Event
        let aggregate: Aggregate<Performer>.Operator = .allMatching
        var primaryKey: Performance.Query {
            let restriction = Aggregate<Performer>(aggregate, records: performers)
            return Performance.Query(performers: restriction, event: event, ability: ability, group: group)
        }
        func update(record: Performance) {
            record.event = event
            record.performers = performers
            record.ability_ = ability
            record.group_ = group
        }
        init(ability: Performance.Ability, group: Performance.Group, performers: Set<Performer>, event: Event) {
            self.ability = ability
            self.group = group
            self.performers = performers
            self.event = event
        }
    }
    let ability: String
    let group: String
    let performers: [JSONPerformer]
    enum CodingKeys: String, CodingKey {
        case ability = "Ability"
        case group = "Group"
        case performers = "Performers"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let ability = try values.decode(String.self, forKey: .ability)
        let group = try values.decode(String.self, forKey: .group)
        let performers = try values.decode([JSONPerformer].self, forKey: .performers)
        self.init(ability: ability, group: group, performers: performers)
    }
    init(ability: String, group: String, performers: [JSONPerformer]) {
        self.ability = ability
        self.group = group
        self.performers = performers
    }
    func export(withEvent event: Event, withParty party: Party, withContext context: NSManagedObjectContext) throws -> Export {
        let performers_: [Performer] = try performers.map {
            let export = $0.export(withParty: party)
            let record = try export.record(in: context)
            return record
        }
        let ability_ = Performance.Ability(rawValue: ability)!
        let group_ = Performance.Group(rawValue: group)!
        return Export(ability: ability_, group: group_, performers: Set(performers_), event: event)
    }
}
