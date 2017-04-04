import XCTest
@testable import GraphTests

XCTMain([
     testCase(GraphTests.allTests),
     testCase(GraphModelStoreTests.allTests),
])
