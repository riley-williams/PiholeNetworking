import XCTest
import Combine
@testable import PiholeNetworking

final class PiholeNetworkingTests: XCTestCase {
	let instance = ConcreteInstance("256.0.0.0")
	var cancellables: Set<AnyCancellable> = []
	let decoder = JSONDecoder()
	
	override func setUp() {
		
	}
	
	final func testHashPassword() throws {
		let instance = ConcreteInstance("1.2.3.4", port: 80, password: "8MzrcBRm")
		
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
	
	final func testSparseClientDataResponse() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		let clientData = try decoder.decode(PH10MinClientData.self, from: data)
		
		measure {
			let _ = PHSparseClientData(data: clientData)
		}
	}
	
	func testInstanceSorting() throws {
		// This is sorted in the desired order
		let pis: [ConcreteInstance] = [ConcreteInstance("4.8.9.255"),
							 ConcreteInstance("192.8.1.11"),
							 ConcreteInstance("192.168.1.10"),
							 ConcreteInstance("192.168.1.10", port: 8080),
							 ConcreteInstance("192.168.1.11"),
							 ConcreteInstance("192.168.1.20"),
							 ConcreteInstance("192.168.2.10", port: 8080),
							 ConcreteInstance("192.168.2.10", port: 8088)]
		
		let uniquePis: Set<ConcreteInstance> = Set(pis)

		XCTAssertEqual(uniquePis.count, pis.count, "Pis are not properly identified")
		
		XCTAssertEqual(uniquePis.sorted(), pis, "Pis are not properly sorted")
		
		XCTAssertFalse(uniquePis.contains(ConcreteInstance("192.168.1.100")))
		XCTAssertFalse(uniquePis.contains(ConcreteInstance("192.168.1.10", port: 8)))
	}

	func testClientSorting() throws {
		// This is in the correct order
		let clients: [PHClient] = [PHClient(name: "a.local", ip: "192.168.1.100"),
									   PHClient(name: "b.local", ip: "192.168.1.50"),
									   PHClient(name: "c.local", ip: "192.168.1.25"),
									   PHClient(name: "", ip: "10.10.1.9"),
									   PHClient(name: "", ip: "10.10.1.11"),
									   PHClient(name: "", ip: "192.168.1.75")]
		let uniqueClients: Set<PHClient> = Set(clients)
		
		XCTAssertEqual(clients.count, uniqueClients.count)
		
		XCTAssertEqual(uniqueClients.sorted(), clients, "Clients are not correctly sorted")
		XCTAssertTrue(uniqueClients.contains(PHClient(name: "name shouldnt matter", ip: "192.168.1.100")))
	}

	
	
	//TODO: Why Apple :/
    static var allTests = [
        ("testHashPassword", testHashPassword),
    ]
}
