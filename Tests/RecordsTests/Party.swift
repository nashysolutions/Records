import CoreData
import Records

@objc(Party)
public class Party: NSManagedObject, Fetchable {
  
  @NSManaged public var email: String
  
  @NSManaged public var name: String
  
  @NSManaged public var phone: String
  
  @NSManaged private var type: String
  
  @NSManaged public var performers: Set<Performer>?
  
  public enum PartyType: String {
    case school = "School"
    case independent = "Independent"
  }
  
  public var type_: PartyType {
    get {
      return PartyType(rawValue: type)!
    }
    set {
      type = newValue.rawValue
    }
  }
  
}

// sourcery:inline:Party.ManagedObject.Query.stencil
public extension Party {
    struct Query {
        public var email: StringParameter?
        public var name: StringParameter?
        public var phone: StringParameter?
        public var performers: Aggregate<Performer>?
        public var type: PartyType?

        public init(email: StringParameter? = nil, name: StringParameter? = nil, phone: StringParameter? = nil, performers: Aggregate<Performer>? = nil, type: PartyType? = nil) {
          self.email = email 
          self.name = name 
          self.phone = phone 
          self.performers = performers 
          self.type = type 
        }
    }
}

extension Party.Query: QueryGenerator {

    public typealias Entity = Party

    public var predicateRepresentation: NSCompoundPredicate? {
      var predicates = [NSPredicate]()
      if let predicate = emailPredicate() {
        predicates.append(predicate)
      }
      if let predicate = namePredicate() {
        predicates.append(predicate)
      }
      if let predicate = phonePredicate() {
        predicates.append(predicate)
      }
      if let predicate = performersPredicate() {
        predicates.append(predicate)
      }
      if let predicate = typePredicate() {
        predicates.append(predicate)
      }
      if predicates.count == 0 {
        return nil
      }
      return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func emailPredicate() -> NSPredicate? {
      guard let email = email else { return nil }
      let value = "email" + " " + email.predicateFormat + " %@"
      return NSPredicate(format: value, email.candidate)
    }
    private func namePredicate() -> NSPredicate? {
      guard let name = name else { return nil }
      let value = "name" + " " + name.predicateFormat + " %@"
      return NSPredicate(format: value, name.candidate)
    }
    private func phonePredicate() -> NSPredicate? {
      guard let phone = phone else { return nil }
      let value = "phone" + " " + phone.predicateFormat + " %@"
      return NSPredicate(format: value, phone.candidate)
    }
    private func performersPredicate() -> NSPredicate? {
      guard let performers = performers else { return nil }
      return performers.predicate("performers")
    }
    private func typePredicate() -> NSPredicate? {
      guard let type = type else { return nil }
      return NSPredicate(format: "type == %@", type.rawValue as CVarArg)
    }
}
// sourcery:end
