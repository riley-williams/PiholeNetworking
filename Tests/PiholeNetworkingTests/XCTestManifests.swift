import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PiholeNetworkingTests.allTests),
		testCase(DecodingTests.allTests)
    ]
}
#endif
