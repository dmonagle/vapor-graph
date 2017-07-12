import XCTest

@testable import VaporGraph

import Vapor

struct NodeFactory {
    static func testNodes() -> (Node, Node) {
        return (
            Node([
                "name": "John",
                "surname": "Smith",
                "title": "Manager",
                "male": true,
                "car": Node([
                    "make": "Ford",
                    "model": "Escort",
                    "year": 1979
                    ])
                ]),
            Node([
                "name": "Sarah",
                "surname": "Smith",
                "age": 65,
                "male": false,
                "car": Node([
                    "make": "Ford",
                    "model": "Falcon",
                    "year": 1992
                    ])
                ])
        )
    }
}

class DiffMergeTests: XCTestCase {
    func testDiff() throws {
        let (n1, n2) =  NodeFactory.testNodes()

        let diff : Node! = try n2.diff(from: n1)
        XCTAssertTrue(diff["title"]?.isNull ?? false)
        XCTAssertEqual(diff["age"]?.int, 65)
        XCTAssertEqual(diff["car"]?["model"]?.string, "Falcon")
        XCTAssertNil(diff["car"]?["make"])
        
        let reverseDiff : Node! = try n1.diff(from: n2)
        XCTAssertEqual(reverseDiff["title"]?.string, "Manager")
        XCTAssertTrue(reverseDiff["age"]?.isNull ?? false)
        XCTAssertEqual(reverseDiff["car"]?["model"]?.string, "Escort")
        XCTAssertNil(reverseDiff["car"]?["make"])
    }
    
    func testMerge() throws {
        let (n1, n2) =  NodeFactory.testNodes()

        let merged : Node! = try n1.merge(with: n2)
        XCTAssertEqual(merged["name"]?.string, "Sarah")
        XCTAssertEqual(merged["surname"]?.string, "Smith")
        XCTAssertEqual(merged["title"]?.string, "Manager")
        XCTAssertEqual(merged["age"]?.int, 65)
        XCTAssertEqual(merged["car"]?["model"]?.string, "Falcon")
    }
    
    static var allTests : [(String, (DiffMergeTests) -> () throws -> Void)] {
        return [
            ("testDiff", testDiff),
            ("testMerge", testMerge),
        ]
    }
}

