import CoreData
import Records

@objc(Performance)
public class Performance: NSManagedObject, Fetchable {

  @NSManaged private var ability: String
  
  @NSManaged private var group: String
  
  @NSManaged public var performers: Set<Performer>
  
  @NSManaged public var event: Event
  
  public enum Ability: String {
    case newcomer = "Newcomer"
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
  }
  
  public enum Group: String {
    case solo = "Solo"
    case duo = "Duo"
    case quad = "Quad"
    case team = "Team"
  }
  
  public var ability_: Ability {
    get {
      return Ability(rawValue: ability)!
    }
    set {
      ability = newValue.rawValue
    }
  }
  
  public var group_: Group {
    get {
      return Group(rawValue: group)!
    }
    set {
      group = newValue.rawValue
    }
  }
  
  public override func validateForInsert() throws {
    try super.validateForInsert()
    try performValidation()
  }
  
  public override func validateForUpdate() throws {
    try super.validateForUpdate()
    try performValidation()
  }
  
  private func performValidation() throws {
    switch group_ {
    case .solo:
      if performers.count != 1 {
        let errString = "A solo must only have 1 performer."
        let userInfo = [NSLocalizedFailureReasonErrorKey: errString, NSValidationObjectErrorKey: self] as [String : Any]
        throw NSError(domain: "PERFORMANCE_ERROR_DOMAIN", code: 1, userInfo: userInfo)
      }
    case .duo:
      if performers.count != 2 {
        let errString = "A duo must only have 2 performers."
        let userInfo = [NSLocalizedFailureReasonErrorKey: errString, NSValidationObjectErrorKey: self] as [String : Any]
        throw NSError(domain: "PERFORMANCE_ERROR_DOMAIN", code: 1, userInfo: userInfo)
      }
    case .quad:
      if performers.count != 4 {
        let errString = "A quad must only have 4 performers."
        let userInfo = [NSLocalizedFailureReasonErrorKey: errString, NSValidationObjectErrorKey: self] as [String : Any]
        throw NSError(domain: "PERFORMANCE_ERROR_DOMAIN", code: 1, userInfo: userInfo)
      }
    case .team:
      if performers.count < 4 {
        let errString = "A team must have at least 4 performers."
        let userInfo = [NSLocalizedFailureReasonErrorKey: errString, NSValidationObjectErrorKey: self] as [String : Any]
        throw NSError(domain: "PERFORMANCE_ERROR_DOMAIN", code: 1, userInfo: userInfo)
      }
    }
  }

}

// sourcery:inline:Performance.ManagedObject.Query.stencil
public extension Performance {
    struct Query {
        public var performers: Aggregate<Performer>?
        public var event: Event?
        public var ability: Ability?
        public var group: Group?

        public init(performers: Aggregate<Performer>? = nil, event: Event? = nil, ability: Ability? = nil, group: Group? = nil) {
          self.performers = performers 
          self.event = event 
          self.ability = ability 
          self.group = group 
        }
    }
}

extension Performance.Query: QueryGenerator {

    public typealias Entity = Performance

    public var predicateRepresentation: NSCompoundPredicate? {
      var predicates = [NSPredicate]()
      if let predicate = performersPredicate() {
        predicates.append(predicate)
      }
      if let predicate = eventPredicate() {
        predicates.append(predicate)
      }
      if let predicate = abilityPredicate() {
        predicates.append(predicate)
      }
      if let predicate = groupPredicate() {
        predicates.append(predicate)
      }
      if predicates.count == 0 {
        return nil
      }
      return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func performersPredicate() -> NSPredicate? {
      guard let performers = performers else { return nil }
      return performers.predicate("performers")
    }
    private func eventPredicate() -> NSPredicate? {
      guard let event = event else { return nil }
      return NSPredicate(format: "event == %@", event as CVarArg)
    }
    private func abilityPredicate() -> NSPredicate? {
      guard let ability = ability else { return nil }
      return NSPredicate(format: "ability == %@", ability.rawValue as CVarArg)
    }
    private func groupPredicate() -> NSPredicate? {
      guard let group = group else { return nil }
      return NSPredicate(format: "group == %@", group.rawValue as CVarArg)
    }
}
// sourcery:end
