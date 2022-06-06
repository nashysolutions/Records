import CoreData
import XCTest

@testable import Records

final class FetchedResultsControllerTests: BaseTests {
    
    override func setUp() {
        super.setUp()
        try! DataBuilder(context: container.viewContext).populateDatabase()
        try! container.viewContext.save()
    }
    
    func testFetchedResultsControllerTests0() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {}
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {}
            func didReload() {}
        }
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        XCTAssert(controller.context == container.viewContext)
    }
    
    func testFetchedResultsControllerTests1() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {}
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {}
            var did = false
            func didReload() {
                did = true
            }
        }
        let delegate = Delegate()
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        XCTAssert(delegate.did == true, "Delegate didReload() did not fire.")
    }
    
    func testFetchedResultsControllerTests2() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {}
            var didInsert = false
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {
                guard tasks.count == 1 else {
                    XCTFail()
                    return
                }
                guard let task = tasks.first else {
                    XCTFail()
                    return
                }
                guard case .insertRowsAt(indexPaths: let indexPaths) = task else {
                    XCTFail()
                    return
                }
                guard let indexPath = indexPaths.first else {
                    XCTFail()
                    return
                }
                XCTAssert(indexPath.section == 0)
                XCTAssert(indexPath.row == 2)
                didInsert = true
            }
            func didReload() {}
        }
        let delegate = Delegate()
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        let event = Event(context: container.viewContext)
        var components = DateComponents()
        components.year = 2018
        components.month = 2
        components.day = 4
        let date = Calendar.current.date(from: components)!
        event.startDate = date
        try container.viewContext.save()
        XCTAssert(delegate.didInsert == true)
    }
    
    func testFetchedResultsControllerTests3() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            var didInsert = false
            func updateCell(at indexPath: IndexPath, for entity: Performance) {}
            func perform(tasks: [FetchedResultsControllerTask<Performance>]) {
                guard tasks.count == 2 else {
                    XCTFail()
                    return
                }
                let firstTask = tasks[0]
                let secondTask = tasks[1]
                guard case .insertSectionAt(section: let section) = firstTask else {
                    XCTFail()
                    return
                }
                guard section == 1 else {
                    XCTFail()
                    return
                }
                guard case .insertRowsAt(indexPaths: let indexPaths) = secondTask else {
                    XCTFail()
                    return
                }
                guard let indexPath = indexPaths.first else {
                    XCTFail()
                    return
                }
                XCTAssert(indexPath.section == 1)
                XCTAssert(indexPath.row == 0)
                didInsert = true
            }
            func didReload() {}
        }
        final class PerformanceController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {
            private let sectionName = "group"
            override func sectionNameKeyPath() -> String? {
                return sectionName
            }
            override func sortDescriptors() -> [NSSortDescriptor] {
                return [NSSortDescriptor(key: sectionName, ascending: true)]
            }
        }
        let delegate = Delegate()
        let controller = try PerformanceController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        let event = try Event.fetchFirst(in: container.viewContext)!
        let performance = Performance(context: container.viewContext)
        performance.event = event
        performance.ability_ = .advanced
        performance.group_ = .quad
        let party = try Party.fetchFirst(in: container.viewContext)!
        for i in 0..<4 {
            let performer = Performer(context: container.viewContext)
            performer.firstName = "firstName\(i)"
            performer.lastName = "lastName\(i)"
            performer.dob = Date()
            performer.party = party
            performance.performers.insert(performer)
        }
        try container.viewContext.save()
        XCTAssert(delegate.didInsert == true)
    }
    
    func testFetchedResultsControllerTests4() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {}
            var didDelete = false
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {
                guard tasks.count == 1 else {
                    XCTFail()
                    return
                }
                guard let task = tasks.first else {
                    XCTFail()
                    return
                }
                guard case .deleteRowsAt(indexPaths: let indexPaths) = task else {
                    XCTFail()
                    return
                }
                guard indexPaths.count == 1 else {
                    XCTFail()
                    return
                }
                guard let indexPath = indexPaths.first else {
                    XCTFail()
                    return
                }
                XCTAssert(indexPath.section == 0)
                XCTAssert(indexPath.row == 0)
                didDelete = true
            }
            func didReload() {}
        }
        let delegate = Delegate()
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        let event = try Event.fetchFirst(in: container.viewContext)!
        container.viewContext.delete(event)
        try container.viewContext.save()
        XCTAssert(delegate.didDelete == true)
    }
    
    func testFetchedResultsControllerTests5() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            var didDelete = false
            func updateCell(at indexPath: IndexPath, for entity: Performance) {}
            func perform(tasks: [FetchedResultsControllerTask<Performance>]) {
                guard tasks.count == 14 else {
                    XCTFail()
                    return
                }
                guard let firstTask = tasks.first else {
                    XCTFail()
                    return
                }
                guard case .deleteRowsAt(indexPaths: _) = firstTask else {
                    XCTFail()
                    return
                }
                guard let lastTask = tasks.last else {
                    XCTFail()
                    return
                }
                guard case .deleteSectionAt(section: let section) = lastTask else {
                    XCTFail()
                    return
                }
                XCTAssert(section == 1)
                didDelete = true
            }
            func didReload() {}
        }
        final class PerformanceController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {
            private let sectionName = "group"
            override func sectionNameKeyPath() -> String? {
                return sectionName
            }
            override func sortDescriptors() -> [NSSortDescriptor] {
                return [NSSortDescriptor(key: sectionName, ascending: true)]
            }
        }
        let delegate = Delegate()
        let controller = try PerformanceController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        let performances = try Performance.Query(group: .solo).all(in: container.viewContext)
        performances.forEach { (performance) in
            container.viewContext.delete(performance)
        }
        try container.viewContext.save()
        XCTAssert(delegate.didDelete == true)
    }
    
    func testFetchedResultsControllerTests7() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {}
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {}
            func didReload() {}
        }
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        try controller.reload()
        var event = Event(context: container.viewContext)
        event.startDate = Date()
        controller.contentChanged = { count in
            XCTAssert(count == 7, "Invalid count. Expected: 7, Actual: \(count)")
        }
        try container.viewContext.save()
        event = Event(context: container.viewContext)
        event.startDate = Date()
        controller.contentChanged = { count in
            XCTAssert(count == 8, "Invalid count. Expected: 8, Actual: \(count)")
        }
        try container.viewContext.save()
    }
        
    func testFetchedResultsControllerTests9() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Performance) {}
            func perform(tasks: [FetchedResultsControllerTask<Performance>]) {}
            func didReload() {}
        }
        final class PerformanceController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {
            override func predicate() -> NSCompoundPredicate {
                let predicate1 = NSPredicate(format: "group == %@", "Solo")
                let predicate2 = NSPredicate(format: "ability == %@", "Newcomer")
                return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            }
        }
        let controller = try PerformanceController<Delegate>(context: container.viewContext)
        try controller.reload()
        let count = controller.fetchedResultsController.fetchedObjects!.count
        let expected: Int = 11
        XCTAssert(count == expected, "Unexpected data. Expected: \(expected). Actual: \(count)")
        let performance = controller.fetchedResultsController.fetchedObjects?.first
        let expectedGroup = Performance.Group.solo
        let actualGroup = String(describing: performance?.group_)
        let message1 = "Unexpected data. Expected: \(expectedGroup). Actual: \(actualGroup)"
        XCTAssert(performance?.group_ == expectedGroup, message1)
        let expectedability = Performance.Ability.newcomer
        let actualAbility = String(describing: performance?.ability_)
        let message2 = "Unexpected data. Expected: \(expectedability). Actual: \(actualAbility)."
        XCTAssert(performance?.ability_ == expectedability, message2)
        var components = DateComponents()
        components.year = 2018
        components.month = 2
        components.day = 4
        let date = Calendar.current.date(from: components)!
        let lower = date.oneDayEarlier
        let upper = date.oneDayLater
        let actualEvent = Event.Query(startDate: lower...upper)
        let expectedEvent = performance!.event
        let message3 = "Unexpected data. Expected event with startDate: \(String(describing: expectedEvent.startDate)). Actual: \(String(describing: actualEvent.startDate))"
        XCTAssert(performance?.event == expectedEvent, message3)
    }
    
    func testFetchedResultsControllerTests10() throws {
        
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Performance) {}
            func perform(tasks: [FetchedResultsControllerTask<Performance>]) {}
            func didReload() {}
        }
        final class PerformanceController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {
            override func predicate() -> NSCompoundPredicate {
                let predicate1 = NSPredicate(format: "group == %@", "Duo")
                let predicate2 = NSPredicate(format: "ability == %@", "Newcomer")
                return NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            }
        }
        let controller = try PerformanceController<Delegate>(context: container.viewContext)
        try controller.reload()
        let count = controller.fetchedResultsController.fetchedObjects!.count
        let expected: Int = 7
        XCTAssert(count == expected, "Unexpected data. Expected: \(expected). Actual: \(count)")
        let performance = controller.fetchedResultsController.fetchedObjects?.first
        let expectedGroup = Performance.Group.duo
        let actualGroup = String(describing: performance?.group_)
        let message1 = "Unexpected data. Expected: \(expectedGroup). Actual: \(actualGroup)"
        XCTAssert(performance?.group_ == expectedGroup, message1)
        let expectedability = Performance.Ability.newcomer
        let actualAbility = String(describing: performance?.ability_)
        let message2 = "Unexpected data. Expected: \(expectedability). Actual: \(actualAbility)."
        XCTAssert(performance?.ability_ == expectedability, message2)
        var components = DateComponents()
        components.year = 2018
        components.month = 2
        components.day = 4
        let date = Calendar.current.date(from: components)!
        let lower = date.oneDayEarlier
        let upper = date.oneDayLater
        let actualEvent = Event.Query(startDate: lower...upper)
        let expectedEvent = performance!.event
        let message3 = "Unexpected data. Expected event with startDate: \(String(describing: expectedEvent.startDate)). Actual: \(String(describing: actualEvent.startDate))"
        XCTAssert(performance?.event == expectedEvent, message3)
    }
    
    func testFetchedResultsControllerTests11() throws {
        final class Delegate: FetchedResultsControllerDelegate {
            func updateCell(at indexPath: IndexPath, for entity: Event) {
                var components = DateComponents()
                components.year = 2018
                components.month = 5
                components.day = 6
                let date = Calendar.current.date(from: components)!
                XCTAssert(entity.startDate == date)
            }
            func perform(tasks: [FetchedResultsControllerTask<Event>]) {}
            func didReload() {}
        }
        let delegate = Delegate()
        final class EventController<D: FetchedResultsControllerDelegate>: FetchedResultsController<D> {}
        let controller = try EventController<Delegate>(context: container.viewContext)
        controller.delegate = delegate
        try controller.reload()
        var components = DateComponents()
        components.year = 2018
        components.month = 5
        components.day = 6
        let date = Calendar.current.date(from: components)!
        let event = try Event.fetchFirst(in: container.viewContext)!
        event.startDate = date
        try container.viewContext.save()
    }
}
