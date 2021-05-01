import CoreData
import XCTest

class BaseTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try StackBuilder().load()
    }
}

private struct StackBuilder {
    
    func load() throws -> NSPersistentContainer {

        let persistentStoreDescription = NSPersistentStoreDescription()
        persistentStoreDescription.type = NSInMemoryStoreType

        let container = NSPersistentContainer(
            name: "Model",
            managedObjectModel: loadModel()
        )
        
        container.persistentStoreDescriptions = [persistentStoreDescription]
        
        container.loadPersistentStores { _, error in
            if error != nil {
                fatalError("Unresolved error")
            }
        }
        return container as NSPersistentContainer
    }
    
    private func loadModel() -> NSManagedObjectModel {
        let url = Bundle.module.url(forResource: "Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: url)!
    }
}
