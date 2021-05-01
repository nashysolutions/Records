import UIKit
import CoreData

/// An interface for extracting records from CoreData
public protocol Fetchable where Self: NSManagedObject {
    associatedtype T: NSFetchRequestResult = Self
}

public extension Fetchable {
    /// This function counts the total records saved for the CoreData Model Entity represented by the invocant of this function.
    ///
    /// - Parameter context: The object associated with the relevant persistent store co-ordinator you would like to query.
    /// - Returns: The total count of records.
    /// - Throws: Errors from the CoreData layer.
    static func count(in context: NSManagedObjectContext) throws -> Int {
        let entityName = typeName(self)
        let request: NSFetchRequest<T> = NSFetchRequest(entityName: entityName)
        return try context.count(for: request)
    }
    /// This function retrieves all saved records for the CoreData Model Entity represented by the invocant of this function.
    ///
    /// - Parameters:
    ///   - predicate: A custom predicate to restrict the query.
    ///   - fetchLimit: The max number of records we want returned to us.
    ///   - context: The object associated with the relevant persistent store co-ordinator you would like to query.
    /// - Returns: Every available record that matches the predicate.
    /// - Throws: Errors from the CoreData layer.
    static func fetchAll(withPredicate predicate: NSPredicate? = nil, withSort sort: [NSSortDescriptor]? = nil, fetchLimit: Int = 0, in context: NSManagedObjectContext) throws -> [T] {
        let entityName = typeName(self)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.fetchLimit = fetchLimit
        request.sortDescriptors = sort
        return try context.fetch(request)
    }
    /// This function retrieves the first saved record found, for the CoreData Model Entity represented by the invocant of this function.
    ///
    /// - Parameters:
    ///   - predicate: A custom predicate to restrict the query.
    ///   - context: The object associated with the relevant persistent store co-ordinator you would like to query.
    ///   - sort: The sorting that should take place, before the first record is selected.
    /// - Returns: The first saved record found. Any other records are ignored.
    /// - Throws: Errors from the CoreData layer.
    static func fetchFirst(withPredicate predicate: NSPredicate? = nil, in context: NSManagedObjectContext, sortedBy sort: [NSSortDescriptor]? = nil) throws -> T? {
        let entityName = typeName(self)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.fetchLimit = 1
        request.sortDescriptors = sort
        let fetch = try context.fetch(request)
        return fetch.first
    }
}

/// An interface for building predicates for CoreData fetch requests for records represented by `Entity`
public protocol QueryGenerator {
    associatedtype Entity: Fetchable
    /// A predicate for CoreData fetch requests
    var predicateRepresentation: NSCompoundPredicate? { get }
}

public extension QueryGenerator  {
    
    func first(in context: NSManagedObjectContext) throws -> Entity? {
        return try first(in: context, sortedBy: nil)
    }
    
    func first(in context: NSManagedObjectContext, sortedBy: [NSSortDescriptor]?) throws -> Entity? {
        return try Entity.fetchFirst(withPredicate: predicateRepresentation, in: context, sortedBy: sortedBy) as? Entity
    }
    
    func all(in context: NSManagedObjectContext) throws -> [Entity] {
        return try Entity.fetchAll(withPredicate: predicateRepresentation, in: context) as! [Entity]
    }
    
}

/// Can be stored as a CoreData record.
public protocol Recordable {
    associatedtype RecordQuery: QueryGenerator where RecordQuery.Entity.T == RecordQuery.Entity
    /// This must be a query for a unique record. If this value is nil, the first record discovered will be overwritten.
    var primaryKey: RecordQuery { get }
    /// Called when a record is to be updated with fresh data
    ///
    /// - Parameter record: The record to be updated.
    func update(record: RecordQuery.Entity)
}

extension Recordable {
    /// The target record that best represents the reciever. If one does not exist, it will be created.
    /// If no primary key is provided, the first record found in the database will be overwritten.
    /// If one does not exist, it will be created.
    ///
    /// - Parameters:
    ///   - context: The context to use for performing this task
    /// - Returns: The record mapped with all matching data.
    /// - Throws: CoreData layer errors
    @discardableResult public func record(in context: NSManagedObjectContext) throws -> RecordQuery.Entity {
        try fetchOrCreate(in: context) { try primaryKey.first(in: context) }
    }
    
    private func fetchOrCreate(in context: NSManagedObjectContext, block: @escaping () throws -> RecordQuery.Entity?) throws -> RecordQuery.Entity {
        if let record = try block() {
            update(record: record)
            return record
        } else {
            let record = RecordQuery.Entity(context: context)
            update(record: record)
            return record
        }
    }
}

public enum FetchedResultsControllerTask<Entity: NSManagedObject> {
    case insertRowsAt(indexPaths: [IndexPath])
    case insertSectionAt(section: Int)
    case deleteRowsAt(indexPaths: [IndexPath])
    case deleteSectionAt(section: Int)
    case update(at: IndexPath, with: Entity)
}

public protocol FetchedResultsControllerDelegate: AnyObject {
    associatedtype Record: NSManagedObject
    func updateCell(at indexPath: IndexPath, for record: Record)
    func perform(tasks: [FetchedResultsControllerTask<Record>])
    func didReload()
}

public extension FetchedResultsControllerDelegate where Self: UICollectionView {
    
    func perform(tasks: [FetchedResultsControllerTask<Record>]) {
        performBatchUpdates({
            go(tasks)
        }, completion: nil)
    }
    
    private func go(_ tasks: [FetchedResultsControllerTask<Record>]) {
        for task in tasks {
            switch task {
            case .deleteRowsAt(indexPaths: let indexPaths):
                deleteItems(at: indexPaths)
            case .deleteSectionAt(section: let section):
                deleteSections(IndexSet(integer: section))
            case .insertRowsAt(indexPaths: let indexPaths):
                insertItems(at: indexPaths)
            case .insertSectionAt(section: let section):
                insertSections(IndexSet(integer: section))
            case .update(at: let indexPath, with: let entity):
                updateCell(at: indexPath, for: entity)
            }
        }
    }
    
    func didReload() {
        reloadData()
    }
}

public extension FetchedResultsControllerDelegate where Self: FetchedResultsTableView {
    
    func perform(tasks: [FetchedResultsControllerTask<Record>]) {
        beginUpdates()
        go(tasks)
        endUpdates()
    }
    
    private func go(_ tasks: [FetchedResultsControllerTask<Record>]) {
        for task in tasks {
            switch task {
            case .deleteRowsAt(indexPaths: let indexPaths):
                deleteRows(at: indexPaths, with: .fade)
            case .deleteSectionAt(section: let section):
                deleteSections(IndexSet(integer: section), with: .automatic)
            case .insertRowsAt(indexPaths: let indexPaths):
                insertRows(at: indexPaths, with: .fade)
            case .insertSectionAt(section: let section):
                insertSections(IndexSet(integer: section), with: .automatic)
            case .update(at: let indexPath, with: let entity):
                updateCell(at: indexPath, for: entity)
            }
        }
    }
    
    func didReload() {
        reloadData()
    }
    
    func updateCell(at indexPath: IndexPath, for record: Record) {
        _ = dequeue(at: indexPath, for: record)
        reloadRows(at: [indexPath], with: .none)
    }
}

open class FetchedResultsController<Delegate: FetchedResultsControllerDelegate>: NSObject, NSFetchedResultsControllerDelegate {
    
    public typealias ContentChanged = (Int) -> Void
    
    public var contentChanged: ContentChanged?
    
    public weak var delegate: Delegate?
    
    public let context: NSManagedObjectContext
    
    public private(set) lazy var fetchedResultsController: NSFetchedResultsController<Delegate.Record> = {
        return build()
    }()
    
    public required init(context: NSManagedObjectContext) throws {
        self.context = context
        super.init()
    }
    
    private func load() throws {
        fetchedResultsController = build()
        try fetchedResultsController.performFetch()
    }
    
    public func reload() throws {
        try load()
        delegate?.didReload()
    }
    
    private func build() -> NSFetchedResultsController<Delegate.Record> {
        let name = typeName(Delegate.Record.self)
        let fetchRequest: NSFetchRequest<Delegate.Record> = NSFetchRequest<Delegate.Record>(entityName: name)
        fetchRequest.fetchBatchSize = fetchBatchSize
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.predicate = self.predicate()
        fetchRequest.sortDescriptors = self.sortDescriptors()
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: sectionNameKeyPath(), cacheName: nil)
        controller.delegate = self
        return controller
    }
    
    open var fetchLimit: Int {
        return 0
    }
    
    open var fetchBatchSize: Int {
        return 100
    }
    
    open func predicate() -> NSCompoundPredicate { return NSCompoundPredicate(andPredicateWithSubpredicates: []) }
    
    open func sortDescriptors() -> [NSSortDescriptor] { return [] }
    
    open func sectionNameKeyPath() -> String? { return nil }
    
    //MARK: NSFetchedResultsControllerDelegate
    
    private var tasks = [FetchedResultsControllerTask<Delegate.Record>]()
    
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tasks.removeAll()
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if newIndexPath != nil {
                insertRowsAt(indexPaths: [newIndexPath!])
            }
        case .delete:
            if indexPath != nil {
                deleteRowsAt(indexPaths: [indexPath!])
            }
        case .update:
            if let entity = anObject as? Delegate.Record, indexPath != nil {
                update(at: indexPath!, with: entity)
            }
        case .move:
            if indexPath != nil {
                deleteRowsAt(indexPaths: [indexPath!])
            }
            if newIndexPath != nil {
                insertRowsAt(indexPaths: [newIndexPath!])
            }
        @unknown default:
            fatalError()
        }
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if case .delete = type {
            deleteSectionAt(section: sectionIndex)
        }
        if case .insert = type {
            insertSectionAt(section: sectionIndex)
        }
    }
    
    private func insertRowsAt(indexPaths: [IndexPath]) {
        let task = FetchedResultsControllerTask<Delegate.Record>.insertRowsAt(indexPaths: indexPaths)
        tasks.append(task)
    }
    
    private func insertSectionAt(section: Int) {
        let task = FetchedResultsControllerTask<Delegate.Record>.insertSectionAt(section: section)
        tasks.append(task)
    }
    
    private func deleteRowsAt(indexPaths: [IndexPath]) {
        let task = FetchedResultsControllerTask<Delegate.Record>.deleteRowsAt(indexPaths: indexPaths)
        tasks.append(task)
    }
    
    private func deleteSectionAt(section: Int) {
        let task = FetchedResultsControllerTask<Delegate.Record>.deleteSectionAt(section: section)
        tasks.append(task)
    }
    
    private func update(at indexPath: IndexPath, with entity: Delegate.Record) {
        let task = FetchedResultsControllerTask<Delegate.Record>.update(at: indexPath, with: entity)
        tasks.append(task)
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.perform(tasks: tasks)
        tasks.removeAll()
        contentChanged?(controller.fetchedObjects?.count ?? 0)
    }
}

public struct Aggregate<T: NSManagedObject> {
    /// Inclusive operators. As per https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html
    ///
    /// - someMatching: Must include at least one.
    /// - allMatching: Must include all.
    /// - noneMatching: Must exclude all.
    public enum Operator {
        case someMatching
        case allMatching
        case noneMatching
    }
    
    let operation: Operator
    let records: Set<T>
    
    public init(_ operation: Operator, records: Set<T>) {
        self.operation = operation
        self.records = records
    }
    
    /// Generates a predicate that restricts the query with an inclusive operator.
    ///
    /// - Parameter name: The name of the relationship
    /// - Returns: The predicate for restricting the query.
    public func predicate(_ name: String) -> NSPredicate {
        switch operation {
        case .allMatching:
            /// https://stackoverflow.com/a/47001325/1951992
            return NSPredicate(format: "SUBQUERY(\(name), $p, $p in %@).@count = %d", records, records.count)
        case .noneMatching:
            /// https://stackoverflow.com/a/19716571/1951992
            return NSPredicate(format: "SUBQUERY(\(name), $p, $p in %@).@count == 0", records)
        case .someMatching:
            return NSPredicate(format: "ANY " + name + " " + "IN" + " " + "%@", records)
        }
    }
    
}

public protocol FetchedResultsTableView: UITableView, FetchedResultsControllerDelegate {
    associatedtype Cell: UITableViewCell
    func dequeue(at indexPath: IndexPath, for record: Record) -> Cell
}

public struct StringParameter {
    
    public enum MatchCondition {
        case exact, beginningWith, contains
    }
    
    public let candidate: String
    let match: MatchCondition
    
    public var predicateFormat: String {
        switch match {
        case .beginningWith:
            return "BEGINSWITH[cd]"
        case .exact:
            return "=="
        case .contains:
            return "CONTAINS[cd]"
        }
    }
    
    public init(candidate: String, match: MatchCondition = .exact) {
        self.candidate = candidate
        self.match = match
    }
}

func typeName(_ some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(type(of: some))"
}

public protocol Procurable {
    static var json: URL { get }
    static var decoder: JSONDecoder { get }
    static func procure(_ completion: @escaping ([Self]) throws -> Void) throws
}

public extension Procurable where Self: Decodable {
    
    static var decoder: JSONDecoder {
        return JSONDecoder()
    }
    
    static func procure(_ completion: @escaping ([Self]) throws -> Void) throws {
        let contents = try String(contentsOf: json)
        var decoded: [Self] = []
        if let data = contents.data(using: .utf8) {
            decoded = try decoder.decode([Self].self, from: data)
        }
        try completion(decoded)
    }
}

public extension Procurable where Self: Decodable & Recordable {
    
    static func archive(in context: NSManagedObjectContext, _ completion: (([Self.RecordQuery.Entity]) -> Void)? = nil) throws {
        try procure { (items) in
            let entities = try items.map {
                try $0.record(in: context)
            }
            if context.hasChanges {
                try context.save()
            }
            completion?(entities)
        }
    }
}
