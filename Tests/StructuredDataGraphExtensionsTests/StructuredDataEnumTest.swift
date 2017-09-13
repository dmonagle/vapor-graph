import XCTest

@testable import StructuredDataGraphExtensions
import JSON

class StructuredDataEnumTest: XCTestCase {
    enum Greeting : String, StructuredDataEnum {
        case prefunctory
        case warm
        case enthusiastic
    }
    
    static var allTests : [(String, (StructuredDataEnumTest) -> () throws -> Void)] {
        return [
            ("testConditionalAssignmentOperator", testConditionalAssignmentOperator),
            ("testConvertEnumToStructuredData", testConvertEnumToStructuredData),
            ("testInitializeEnumWithStructuredData", testInitializeEnumWithStructuredData),
            ("testInitializeEnumWithStructuredData", testInitializeEnumWithStructuredData),
            ("testEnumAssignmentFromJSON", testEnumAssignmentFromJSON),
        ]
    }
    
    func testConditionalAssignmentOperator() throws {
        let json = JSON(["Hello": "Goodbye", "null": JSON.null])
        var string : String = "UnSet"
        
        try string =? json["Blah"]
        XCTAssertEqual(string, "UnSet")
        
        try string =? json["Hello"]
        XCTAssertEqual(string, "Goodbye")

        try string =? json["null"]
        XCTAssertEqual(string, "Goodbye")

        var nString : String?
        
        try nString =? json["Blah"]
        XCTAssertNil(nString)
        try nString =? json["Hello"]
        XCTAssertEqual(nString, "Goodbye")
        try nString =? json["null"]
        XCTAssertNil(nString)
    }
    
    func testConvertEnumToStructuredData() throws {
        let g = Greeting.prefunctory
        
        let sd : JSON = try g.makeStructuredData()
        XCTAssertEqual(sd.string, "prefunctory")
    }
    
    func testInitializeEnumWithStructuredData() throws {
        var sd = JSON("enthusiastic")
        var g = Greeting.init(structuredData: sd)
        XCTAssertEqual(g, Greeting.enthusiastic)
        
        sd = JSON("blah")
        g = Greeting.init(structuredData: sd)
        XCTAssertNil(g)
    }
    
    func testEnumAssignmentFromJSON() throws {
        let sd = JSON(["greeting": "warm"])
        var greeting : Greeting?
        
        try greeting =? sd["greeting"]
        XCTAssertEqual(greeting, .warm)
        
        try greeting =? sd["nope"]
        XCTAssertEqual(greeting, .warm) // Shouldn't change
    }
    
}
