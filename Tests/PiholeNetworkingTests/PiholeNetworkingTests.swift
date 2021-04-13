import XCTest
import Combine
@testable import PiholeNetworking

final class PiholeNetworkingTests: XCTestCase {
	var cancellables: Set<AnyCancellable> = []
	let decoder = JSONDecoder()
	let unauthenticatedInstance = ConcreteInstance("1.2.3.4")
	let authenticatedInstance = ConcreteInstance("1.2.3.4", password: "1234")
	
	override func setUp() {
		
	}
	
	final func testAPIKeyGeneration() throws {
		let instance = ConcreteInstance("1.2.3.4", port: 80, password: "8MzrcBRm")
		XCTAssertEqual(instance.apiKey, "af90e024ac7f515011ae0c9b326a7e9ff7a00fa9d7f770d323c848f12659e3b9")
	}
	
	final func testAPIKeyFromNilPassword() throws {
		let instance = ConcreteInstance("1.2.3.4")
		XCTAssertNil(instance.apiKey)
	}
	
	final func testGetSummary() throws {
		let session = MockSession(result: MockJSON.summaryRaw)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getSummary(ConcreteInstance("1.2.3.4"))
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
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testDecodeClientData() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		_ = try decoder.decode(PHClientTimeline.self, from: data)
	}
	
	final func testDecodeTopQueries() throws {
		let session = MockSession(result: MockJSON.topItems)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getTopQueries(authenticatedInstance, count: 10)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { topQueries in
				XCTAssertEqual(topQueries.topPassed.count, 10)
				XCTAssertEqual(topQueries.topBlocked.count, 10)
				XCTAssertEqual(topQueries.topPassed["diagnostics.meethue.com"], 209)
				XCTAssertEqual(topQueries.topBlocked["osb-ussvc.samsungqbe.com"], 20)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	final func testDecode10MinData() throws {
		let session = MockSession(result: MockJSON.overTimeData10Mins)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getRequestRatioTimeline(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { timeline in
				XCTAssertEqual(timeline.domains["1615774500"], 37)
				XCTAssertEqual(timeline.ads["1615824300"], 24)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testSparseClientTimelineResponse() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		let clientData = try decoder.decode(PHClientTimeline.self, from: data)
		
		measure {
			let _ = PHSparseClientTimeline(data: clientData)
		}
	}
	
	final func testGetForwardingDestinations() throws {
		let session = MockSession(result: MockJSON.getForwardDestinations)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getForwardDestinations(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { destinations in
				XCTAssertEqual(destinations.count, 5)
				XCTAssertTrue(destinations.contains { $0.key == .cache })
				XCTAssertTrue(destinations.contains { $0.key == .blocklist })
				XCTAssertTrue(destinations.contains { $0.key == .remote(name: "unifi.udm", ip: "192.168.1.1") })
				XCTAssertFalse(destinations.contains { $0.key == .remote(name: "bad.udm", ip: "0.0.0.0") })
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetHWInfo() throws {
		let session = MockSession(result: MockJSON.index)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getHWInfo(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { info in
				XCTAssertEqual(info.cpuTemp!, 39.16, accuracy: 0.05)
				XCTAssertEqual(info.load1Min!, 0.03, accuracy: 0.005)
				XCTAssertEqual(info.load5Min!, 0.07, accuracy: 0.005)
				XCTAssertEqual(info.load15Min!, 0.08, accuracy: 0.005)
				XCTAssertEqual(info.memoryUsage!, 38, accuracy: 0.1)
				promise.fulfill()
			}.store(in: &cancellables)
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

}
