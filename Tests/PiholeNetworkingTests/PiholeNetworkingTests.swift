import XCTest
import Combine
@testable import PiholeNetworking

final class PiholeNetworkingTests: XCTestCase {
	
	override func setUp() {
		
	}
	
	final func testAPIKeyGeneration() throws {
		let instance = ConcreteInstance("1.2.3.4", port: 80, password: "8MzrcBRm")
		XCTAssertEqual(instance.apiKey, "af90e024ac7f515011ae0c9b326a7e9ff7a00fa9d7f770d323c848f12659e3b9")
	}
	
	final func testAPIKeyFromNilPassword() throws {
		let instance = ConcreteInstance("1.2.3.4")
		XCTAssertNotNil(instance.apiKey)
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
		let clients: [PHClient] = [PHClient(ip: "192.168.1.100", name: "a.local"),
								   PHClient(ip: "192.168.1.50", name: "b.local"),
								   PHClient(ip: "192.168.1.25", name: "c.local"),
								   PHClient(ip: "10.10.1.9"),
								   PHClient(ip: "10.10.1.11"),
								   PHClient(ip: "192.168.1.75")]
		let uniqueClients: Set<PHClient> = Set(clients)
		
		XCTAssertEqual(clients.count, uniqueClients.count)
		
		XCTAssertEqual(uniqueClients.sorted(), clients, "Clients are not correctly sorted")
		XCTAssertTrue(uniqueClients.contains(PHClient(ip: "192.168.1.100", name: "name shouldnt matter")))
	}

}
