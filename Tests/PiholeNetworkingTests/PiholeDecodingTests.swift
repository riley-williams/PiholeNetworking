//
//  PiholeDecodingTests.swift
//  PiholeNetworkingTests
//
//  Created by Riley Williams on 4/12/21.
//

import XCTest
import Combine
@testable import PiholeNetworking


class PiholeDecodingTests: XCTestCase {
	var cancellables: Set<AnyCancellable> = []
	let decoder = JSONDecoder()
	let unauthenticatedInstance = ConcreteInstance("1.2.3.4")
	let authenticatedInstance = ConcreteInstance("1.2.3.4", password: "1234")
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
	
	final func testDecodeRequestRatioTimeline() throws {
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
	
	final func testGetClientTimeline() throws {
		let session = MockSession(result: MockJSON.overTimeDataClients)
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getClientTimeline(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { clientTimeline in
				XCTAssertGreaterThan(clientTimeline.clients.count, 0)
				XCTAssertEqual(clientTimeline.clients.count, clientTimeline.timestamps.first!.value.count)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}

	final func testUnauthenticatedResponse() throws {
		let session = MockSession(result: "[]")
		let provider = PHProvider(session: session)
		
		let promise = XCTestExpectation()
		provider.getClientTimeline(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, .authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { clientTimeline in
				XCTFail("Did not expect to receive a value")
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
}
