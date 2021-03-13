import XCTest
@testable import PiholeNetworking

final class DecodingTests: XCTestCase {
	let decoder = JSONDecoder()
	
	func testDecodeStatus() throws {
		guard let data = MockJSON.status.data(using: .utf8),
			  let status = try? decoder.decode(PHStatus.self, from: data) else {
			XCTFail("Unable to decode sample JSON")
			return
		}
		
		XCTAssertEqual(status.state, .enabled)
		XCTAssertEqual(status.blockedDomainCount, 92_699)
	}

	static var allTests = [
		("testDecodeStatus", testDecodeStatus),
	]
}
