import XCTest
import Combine
@testable import PiholeNetworking

final class PiholeNetworkingTests: XCTestCase {
	let instance = ConcreteInstance(hostname: "256.0.0.0")
	var cancellables: Set<AnyCancellable> = []
	let decoder = JSONDecoder()
	
	override func setUp() {
		
	}
	
	final func testHashPassword() throws {
		let instance = ConcreteInstance(hostname: "1.2.3.4", port: 80, password: "8MzrcBRm")
		
		XCTAssertEqual(instance.hashedPassword, "af90e024ac7f515011ae0c9b326a7e9ff7a00fa9d7f770d323c848f12659e3b9")
	}
	
	final func testDecodeSummaryRaw() throws {
		let data = MockJSON.summaryRaw.data(using: .utf8)!
		let summary = try decoder.decode(PHStatus.self, from: data)
		
		XCTAssertEqual(summary.dnsQueryTodayCount, 6673)
	}
	
	final func testDecodeClientData() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		_ = try decoder.decode(PH10MinClientData.self, from: data)
	}
	
	final func testDecodeTopQueries() throws {
		let data = MockJSON.topItems.data(using: .utf8)!
		_ = try decoder.decode(PHTopQueries.self, from: data)
	}
	final func testDecode10MinData() throws {
		let data = MockJSON.overTimeData10Mins.data(using: .utf8)!
		_ = try decoder.decode(PH10MinData.self, from: data)
	}
	
	//TODO: Why Apple :/
    static var allTests = [
        ("testHashPassword", testHashPassword),
    ]
}
