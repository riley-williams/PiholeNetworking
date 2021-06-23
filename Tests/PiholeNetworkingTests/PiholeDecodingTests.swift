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


	final func testGetSummary() async throws {
		let session = MockSession(result: MockJSON.summaryRaw)
		let provider = PHProvider(session: session)
		
		let summary = try await provider.getSummary(ConcreteInstance("1.2.3.4"))
			
		XCTAssertEqual(summary.queryCount, 6673)
		XCTAssertEqual(summary.gravityInfo.lastUpdate.timeIntervalSince1970, 1615696687, accuracy: 1.0)
	}
	
	final func testDecodeTopQueries() async throws {
		let session = MockSession(result: MockJSON.topItems)
		let provider = PHProvider(session: session)
		
		let topQueries = try await provider.getTopQueries(authenticatedInstance, max: 10)
	
		XCTAssertEqual(topQueries.topPassed.count, 10)
		XCTAssertEqual(topQueries.topBlocked.count, 10)
		XCTAssertEqual(topQueries.topPassed["diagnostics.meethue.com"], 209)
		XCTAssertEqual(topQueries.topBlocked["osb-ussvc.samsungqbe.com"], 20)
	}
	
	final func testDecodeTopBlockedClients() async throws {
		let session = MockSession(result: MockJSON.topClientsBlocked)
		let provider = PHProvider(session: session)
		
		let clients = try await provider.getTopBlockedClients(authenticatedInstance, max: 10)
			
		XCTAssertEqual(clients.count, 6)
		XCTAssertEqual(clients[PHClient(pipedString: "localhost.UDM|192.168.1.158")!], 97)
	}
	
	final func testDecodeTopClients() async throws {
		let session = MockSession(result: MockJSON.getQuerySources)
		let provider = PHProvider(session: session)
		
		let clients = try await provider.getTopClients(authenticatedInstance, max: 20)
			
		XCTAssertEqual(clients.count, 18)
		XCTAssertEqual(clients[PHClient(pipedString: "localhost|127.0.0.1")!], 1940)
	}
	
	final func testDecodeRequestRatioTimeline() async throws {
		let session = MockSession(result: MockJSON.overTimeData10Mins)
		let provider = PHProvider(session: session)
		
		let timeline = try await provider.getRequestRatioTimeline(authenticatedInstance)
	
		XCTAssertEqual(timeline.domains["1615774500"], 37)
		XCTAssertEqual(timeline.ads["1615824300"], 24)
	}
	
	final func testDecodeRequestRatioTimelineExperimental() async throws {
		let session = MockSession(result: MockJSON.overTimeData10Mins)
		let provider = PHProvider(session: session)
				
		let timeline = try await provider.getRequestRatioTimeline(authenticatedInstance, from: Date(), until: Date(), interval: 123)

		XCTAssertEqual(timeline.domains["1615774500"], 37)
		XCTAssertEqual(timeline.ads["1615824300"], 24)
	}
	
	final func testDecodeNetworkExperimental() async throws {
		let session = MockSession(result: MockJSON.network)
		let provider = PHProvider(session: session)
				
		let network = try await provider.getNetwork(authenticatedInstance)
		
		XCTAssertEqual(network.count, 5)
	}
	
	final func testSparseClientTimelineConversion() throws {
		let data = MockJSON.overTimeDataClients.data(using: .utf8)!
		let clientData = try decoder.decode(PHClientTimeline.self, from: data)
		
		measure {
			let _ = PHSparseClientTimeline(data: clientData)
		}
	}
	
	final func testGetForwardingDestinations() async throws {
		let session = MockSession(result: MockJSON.getForwardDestinations)
		let provider = PHProvider(session: session)
		
		let destinations = try await provider.getForwardDestinations(authenticatedInstance)

		XCTAssertEqual(destinations.count, 5)
		XCTAssertTrue(destinations.contains { $0.key == .cache })
		XCTAssertTrue(destinations.contains { $0.key == .blocklist })
		XCTAssertTrue(destinations.contains { $0.key == .remote(name: "unifi.udm", ip: "192.168.1.1") })
		XCTAssertFalse(destinations.contains { $0.key == .remote(name: "bad.udm", ip: "0.0.0.0") })
	}
	
	final func testGetQueryTypes() async throws {
		let session = MockSession(result: MockJSON.getQueryTypes)
		let provider = PHProvider(session: session)
		
		let types = try await provider.getQueryTypes(authenticatedInstance)
		
		XCTAssertEqual(types.count, 13)
		XCTAssertEqual(types["A (IPv4)"]!, 35.5, accuracy: 0.1)
	}
	
	final func testGetHWInfo() async throws {
		let session = MockSession(result: MockJSON.index)
		let provider = PHProvider(session: session)
		
		let info = try await provider.getHWInfo(authenticatedInstance)
			
		XCTAssertEqual(info.cpuTemp!, 39.16, accuracy: 0.05)
		XCTAssertEqual(info.load1Min!, 0.03, accuracy: 0.005)
		XCTAssertEqual(info.load5Min!, 0.07, accuracy: 0.005)
		XCTAssertEqual(info.load15Min!, 0.08, accuracy: 0.005)
		XCTAssertEqual(info.memoryUsage!, 38, accuracy: 0.1)
	}
	
	final func testGetClientTimeline() async throws {
		let session = MockSession(result: MockJSON.overTimeDataClients)
		let provider = PHProvider(session: session)
		
		let clientTimeline = try await provider.getClientTimeline(authenticatedInstance)
			
		XCTAssertGreaterThan(clientTimeline.clients.count, 0)
		XCTAssertEqual(clientTimeline.clients.count, clientTimeline.timestamps.first!.value.count)
	}

	final func testUnauthenticatedResponse() async throws {
		let session = MockSession(result: "[]")
		let provider = PHProvider(session: session)
		
		do {
			_ = try await provider.getClientTimeline(unauthenticatedInstance)
			XCTFail("Did not expect to receive a value")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, .authenticationRequired)
		} catch {
			XCTFail("Unexpected error type: \(error)")
		}
	}
}
