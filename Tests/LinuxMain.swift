import XCTest

import PiholeNetworkingTests
import DecodingTests

var tests = [XCTestCaseEntry]()

tests += PiholeNetworkingTests.allTests()
tests += DecodingTests.allTests()

XCTMain(tests)
