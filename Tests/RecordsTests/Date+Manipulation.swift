import Foundation

extension Date {
  
  var oneDayLater: Date {
    let calendar = Calendar(identifier: .gregorian)
    var components = DateComponents()
    components.day = 1
    return calendar.date(byAdding: components, to: self)!
  }
  
  var oneDayEarlier: Date {
    let calendar = Calendar(identifier: .gregorian)
    var components = DateComponents()
    components.day = -1
    return calendar.date(byAdding: components, to: self)!
  }
}
