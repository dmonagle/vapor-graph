import XCTest

@testable import VaporGraph

import Vapor

class GraphableTests: XCTestCase {
    func testSnapshotRestore() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let graph = Graph()
        let dave = Person(named: "Dave")
        dave.id = 1
        dave.rating = 9
        try _ = graph.inject(dave, takeSnapshot: true)
        
        // Should not need a sync as we took a snapshot while inserting
        XCTAssertFalse(try dave.needsSync())
        dave.rating = 4
        XCTAssertTrue(try dave.needsSync())
        
        try dave.revertToSnapshot()
        
        XCTAssertEqual(dave.rating, 9)
        XCTAssertFalse(try dave.needsSync())
    }

    static var allTests : [(String, (GraphableTests) -> () throws -> Void)] {
        return [
            ("testSnapshotRestore", testSnapshotRestore),
        ]
    }
}

