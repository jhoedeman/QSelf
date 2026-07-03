import Foundation

/// A regimen item's start, stop, or long-cycle transition, synthesised from
/// `RegimenItem` records for the Trends swimlane. Not a stored model.
struct RegimenEvent: Identifiable {

    enum Kind {
        case started
        case stopped
        case cycleTransition
    }

    let id = UUID()
    let date: Date
    let itemName: String
    let category: RegimenCategory
    let kind: Kind
}
