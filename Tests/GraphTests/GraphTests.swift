import XCTest

@testable import VaporGraph

import Vapor

class GraphTests: XCTestCase {
    func testStoreAndRetrieve() throws {
        let graph = Graph()
        let tommy = Person.Tommy
        tommy.id = 1
        
        XCTAssertNil(graph.store(forType: Person.self))
        XCTAssertNil(tommy.graph)
        try _ = graph.inject(tommy)
        XCTAssertNotNil(tommy.graph)
        
        XCTAssertNotNil(graph.store(forType: Person.self))
        
        let retrieved : Person? = try graph.retrieve(id: Node(1))
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Tommy")
        XCTAssert(tommy === retrieved)
    }
    
    func testStoreWithGeneratedId() throws {
        let graph = Graph()
        let tommy = Person.Tommy
        
        XCTAssertNil(tommy.id)
        try _ = graph.inject(tommy)
        XCTAssertNotNil(tommy.id)
    }
    
    func testInjectWithRebase() throws {
        let graph = Graph()

        let tommy = Person.Tommy
        tommy.id = 1
        _ = try graph.inject(tommy, takeSnapshot: true)
        tommy.favoriteColor = "White"

        // tommy2 has the same ID as the original but the rating has been changed
        let tommy2 = Person.Tommy
        tommy2.id = 1
        tommy2.rating = 8

        // We inject the second Tommy
        let injected = try graph.inject(tommy2, duplicateResolution: .rebase)
        XCTAssertTrue(injected === tommy) // The return should be the original tommy object
        
        XCTAssertEqual(tommy.favoriteColor, "White") // The original change should be preserved
        XCTAssertEqual(tommy.rating, 8) // Wheras the new rating applied to Tommy2 should survive
    }
    
    static var allTests : [(String, (GraphTests) -> () throws -> Void)] {
        return [
            ("testStoreAndRetrieve", testStoreAndRetrieve),
            ("testStoreWithGeneratedId", testStoreWithGeneratedId),
            ("testInjectWithRebase", testInjectWithRebase),
        ]
    }
}

