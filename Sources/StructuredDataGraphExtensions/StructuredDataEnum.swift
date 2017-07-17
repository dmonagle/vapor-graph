import Node

public protocol StructuredDataEnum : StructuredDataConvertible {
    var rawValue : String { get }
    init?(rawValue: String)
}

extension StructuredDataEnum {
    /// Initializes with StructuredData
    public init?<T>(structuredData: T?) where T : StructuredDataWrapper {
        guard let text = structuredData?.string, let value = Self.init(rawValue: text) else { return nil }
        self = value
    }
    
    public func makeStructuredData<T>() throws -> T where T : StructuredDataWrapper {
        return T(rawValue)
    }
}
