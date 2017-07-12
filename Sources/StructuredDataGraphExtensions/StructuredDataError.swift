import Node
import Foundation

enum StructuredDataError : Error, CustomStringConvertible {
    case initFailedWithValue(StructuredDataInitializable.Type, StructuredData)
    
    var description: String {
        get {
            switch self {
            case .initFailedWithValue(let type, let value):
                return "Could not initialize \(type) with value: '\(value)'"
            }
        }
    }
}
