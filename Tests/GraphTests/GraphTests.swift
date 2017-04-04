import XCTest

@testable import Graph

import Vapor

class GraphTests: XCTestCase {
    func testStoreAndRetrieve() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let graph = Graph()
        var dave = Person(named: "Dave")
        dave.id = 1
        
        XCTAssertNil(graph.store(forType: Person.self))
        XCTAssertNil(dave.graph)
        try graph.add(dave)
        XCTAssertNotNil(dave.graph)
        
        XCTAssertNotNil(graph.store(forType: Person.self))
        
        let retrieved : Person? = try graph.retrieve(id: Node(1))
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Dave")
    }
    
    static var allTests : [(String, (GraphTests) -> () throws -> Void)] {
        return [
            ("testStoreAndRetrieve", testStoreAndRetrieve),
        ]
    }
}

