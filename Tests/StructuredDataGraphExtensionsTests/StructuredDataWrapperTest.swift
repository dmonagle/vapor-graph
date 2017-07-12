import XCTest

@testable import StructuredDataGraphExtensions
import JSON

class StructuredDataWrapperTest: XCTestCase {
    enum Greeting : String, StructuredDataEnum {
        case prefunctory
        case warm
        case enthusiastic
    }
    
    static var allTests : [(String, (StructuredDataWrapperTest) -> () throws -> Void)] {
        return [
            ("testDefaultGet", testDefaultGet),
        ]
    }
    
    func testDefaultGet() throws {
        let sd = JSON(["greeting": "warm"])
        var greeting : Greeting?
        
        try greeting = sd.get("greeting", default: .prefunctory)
        XCTAssertEqual(greeting, .warm)
        
        try greeting = sd.get("nope", default: .prefunctory)
        XCTAssertEqual(greeting, .prefunctory) // Default
    }
    
}
