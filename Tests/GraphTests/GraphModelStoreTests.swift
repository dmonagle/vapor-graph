//
//  GraphModelStoreTests.swift
//  Graph
//
//  Created by David Monagle on 20/3/17.
//
//

import XCTest
import Fluent
@testable import Graph

class GraphModelStoreTests: XCTestCase {
    func testStoreAndRetrieve() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let store = GraphModelStore()
        let dave = Person(named: "Dave")
        dave.id = 1
    
        XCTAssertEqual(store.count, 0)
        try store.add(dave)
        
        XCTAssertEqual(store.count, 1)
        
        let retrieved : Person? = try store.retrieve(id: Node(1))
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Dave")
    }

    static var allTests : [(String, (GraphModelStoreTests) -> () throws -> Void)] {
        return [
            ("testStoreAndRetrieve", testStoreAndRetrieve),
        ]
    }
}
