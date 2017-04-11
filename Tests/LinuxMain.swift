import XCTest
@testable import GraphTests

XCTMain([
     testCase(GraphTests.allTests),
     testCase(GraphableTests.allTests),
     testCase(GraphModelStoreTests.allTests),
])
