# Records

A light-weight wrapper around some of the CoreData API.

## Demo

 - [Demo 1](https://github.com/nashysolutions/RecordsDemo1)
 - [Demo 2](https://github.com/nashysolutions/RecordsDemo2)

## Usage

![](https://user-images.githubusercontent.com/64097812/112747129-39648280-8fab-11eb-81eb-cd6482e5ddde.png)

With the assistance of [Sourcery](https://github.com/krzysztofzablocki/Sourcery) the following code is dynamically updated to reflect immediate changes in your schema. So for instance, if the attribute `group` was removed from the entity `Performance`, the following code would no longer compile.

### Query

```swift
do {
    let query = Performance.Query(group: .solo)
    let performances = try query.all(in: context)
} catch {
    // Errors from the CoreData layer such as 'model not found' etc
}
```

### Create

```swift
struct Information {
    let name: String
    let phone: String
    let email: String
    let type: String
}

extension Information: Recordable {
  // implementation here ~ 2 minutes
}

let info = Information(name: "DanceSchool", phone: "01234567891", email: "dance@school.com", type: "School")

do {
    // The record will be fetched from the database if it exists. 
    // If it does not exist, it will be created and then returned. 
    // The onus is on you to save. 
    // You can check if the context has changes (use `.hasChanges` on the context).
    let record: Party = try info.record(in: context)
} catch {
    // Errors from the CoreData layer such as 'model not found' etc
}
```

### Relationships

If we wanted to query for a `Performer` belonging to a particular `Party`, we would couple the data together.

```swift
struct Person {
    let firstName: String
    let lastName: String
}

extension Person {
  
    // Couple person and party data together
    struct Export {
        let firstName: String
        let lastName: String
        let party: Party // NSManagedObject subclass
    }

    func couple(with party: Party) -> Export {
        Export(firstName: firstName, lastName: lastName, party: party)
    }
}

extension Person.Export: Recordable {
    // implementation here ~ 2 minutes
}

let person = Person(firstName: "Stacey", lastName: "Turner")
let party: Party ... // fetch or create a party
let export = person.couple(with: party)
let record: Performer = try! export.record(in: context)
```

Or we can use an `Aggregate` in our `Query`.

1. include `Performer1` and `Performer2` (.allMatching)
2. include `Performer1` or `Performer2` (.someMatching)
3. exclude `Performer1` and `Performer2` (.noneMatching)

```swift
let aggregate = Aggregate<Performer>(.allMatching, records: Set([performer1, performer2]))
let query = Performance.Query(performers: aggregate)
let performances: [Performance] = try! query.all(in: context)
```

### Observe 

The below table view responds to any database CRUD activity concerning `Event` records. See Wiki for details.

```swift
import UIKit

final class EventsViewController: UIViewController {
    
    let eventController = EventController<EventTableView>() 
    
    private lazy var tableViewHandler = EventTableViewHandler(eventController)
    
    @IBOutlet weak var tableView: EventTableView! {
        didSet {
            tableView.dataSource = tableViewHandler
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eventController.delegate = tableView
        try! eventController.reload()
    }
}
```

## Installation

Copy this [template file](https://github.com/nashysolutions/RecordsDemo1/blob/master/Performances/Database/Stencils/ManagedObjectQuery.stencil) to your project.

Install [Sourcery](https://github.com/krzysztofzablocki/Sourcery).

List this package in your `Package.swift` manifest file as a [Swift Package](https://swift.org/package-manager/) dependency. [Releases Page](https://github.com/nashysolutions/Records/releases).

Create the following file at the root directory of your project.

```bash
.sourcery.yml
```

This file should contain the following

```ruby
sources:
  - ./path/to/your/NSManagedObject/subclasses
templates:
  - ./path/to/your/template/file
output:
  ./path/to/your/NSManagedObject/subclasses
```

Run the following script as a `run script build phase`, just before the build phase named `compile sources`.

```bash
/opt/homebrew/bin/sourcery --config ./.sourcery.yml
```

In your core data model file, set codgen to 'manual' for each of your CoreData entities.

In each of your NSManagedObject subclasses:

1. Declared conformance to `Fetchable`.
2. Add annotation marks for Sourcery.
3. Change `NSSet` to `Set<Something>`

For example, `Performer`, should look like the following (Assuming your template file is called `ManagedObject.Query.stencil`).

```swift
import CoreData
import Records

@objc(Performer)
public class Performer: NSManagedObject, Fetchable {
@NSManaged public var dob: Date
@NSManaged public var firstName: String
@NSManaged public var lastName: String
@NSManaged public var party: Party
//@NSManaged public var performances: NSSet?
@NSManaged public var performances: Set<Performance>?
}

// sourcery:inline:Performer.ManagedObjectQuery.stencil
// sourcery:end
```

All done
