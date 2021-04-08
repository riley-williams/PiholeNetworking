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
	
	final func testHashNilPassword() throws {
		let instance = ConcreteInstance("1.2.3.4")
		XCTAssertNil(instance.hashedPassword)
	}
	
	final func testGetSummary() throws {
		let session = DisposableMockSession(result: MockJSON.summaryRaw)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		let cancellable = provider.getSummary(ConcreteInstance("1.2.3.4"))
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { summary in
				XCTAssertEqual(summary.dnsQueryTodayCount, 6673)
				promise.fulfill()
			}
		wait(for: [promise], timeout: 1)
	}
	
	final func testDecodeClientData() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		_ = try decoder.decode(PHClientTimeline.self, from: data)
	}
	
	final func testDecodeTopQueries() throws {
		let data = MockJSON.topItems.data(using: .utf8)!
		_ = try decoder.decode(PHTopQueries.self, from: data)
	}
	final func testDecode10MinData() throws {
		let data = MockJSON.overTimeData10Mins.data(using: .utf8)!
		_ = try decoder.decode(PHRequestRatioTimeline.self, from: data)
	}
	
	final func testSparseClientTimelineResponse() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		let clientData = try decoder.decode(PHClientTimeline.self, from: data)
		
		measure {
			let _ = PHSparseClientTimeline(data: clientData)
		}
	}
	
	final func testGetForwardingDestinations() throws {
		let data = MockJSON.getForwardDestinations.data(using: .utf8)!
		_ = try decoder.decode([String:[PHForwardDestination:Float]].self, from: data)
		
		
		let session = DisposableMockSession(result: MockJSON.getForwardDestinations)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		let cancellable = provider.getForwardDestinations(ConcreteInstance("1.2.3.4", password: "123"))
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { destinations in
				print(destinations)
				promise.fulfill()
			}
		wait(for: [promise], timeout: 1)
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
	
	
	
	//TODO: Why Apple :/
	static var allTests = [
		("testHashPassword", testHashPassword),
	]
}
