//
//  GraphModelStoreTests.swift
//  Graph
//
//  Created by David Monagle on 20/3/17.
//
//

import XCTest
import Fluent
@testable import VaporGraph

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
        
        let retrieved : Person? = store.retrieve(id: 1)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Dave")
    }
    
    func testFilter() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let store = GraphModelStore()
        let dave = Person(named: "Dave")
        dave.id = 1
        let alan = Person(named: "Alan")
        alan.id = 2
        
        try store.add(dave)
        try store.add(alan)
        
        
        let f1 : [Person] = try store.filter { person in
            return person.name == "Dave" ? true : false
        }
        
        XCTAssertEqual(f1.count, 1)
        XCTAssertEqual(f1[0].name, "Dave")
    }
    
    static var allTests : [(String, (GraphModelStoreTests) -> () throws -> Void)] {
        return [
            ("testStoreAndRetrieve", testStoreAndRetrieve),
            ("testFilter", testFilter),
        ]
    }
}
