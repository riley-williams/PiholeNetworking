//
//  PiholeIntegrationTests.swift
//  PiholeNetworkingTests
//
//  Created by Riley Williams on 4/12/21.
//

import XCTest
import Combine
import PiholeNetworking

class PiholeIntegrationTests: XCTestCase {
	var cancellables: Set<AnyCancellable> = []
	let unauthenticatedInstance = ConcreteInstance("192.168.1.168", password: "asdf")
	let authenticatedInstance = ConcreteInstance("192.168.1.168", password: "admin")

	var isXcodeServer: Bool {
		#if XCS
		return true
		#else
		return false
		#endif
	}

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    final func testAuthentication() async throws {
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
    }

	final func testGetSummary() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let summary = try await handle.getSummary()

		XCTAssertGreaterThan(summary.queryCount, 0)
		let computedCount = Float(summary.blockedQueryCount)/Float(summary.queryCount)*100
		XCTAssertEqual(computedCount, summary.percentAds, accuracy: 0.5)
	}
	
	final func testGetTopQueries() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let topQueries = try await handle.getTopQueries(max: 6)

		XCTAssertLessThanOrEqual(topQueries.topPassed.count, 6)
		XCTAssertLessThanOrEqual(topQueries.topBlocked.count, 6)
	}

	final func testGetTopBlockedClients() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let clients = try await handle.getTopBlockedClients(max: 3)

		XCTAssertGreaterThan(clients.count, 0)
		XCTAssertLessThanOrEqual(clients.count, 3)
	}
	
	final func testGetTopClients() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let clients = try await handle.getTopClients(max: 3)

		XCTAssertGreaterThan(clients.count, 0)
		XCTAssertLessThanOrEqual(clients.count, 3)
	}

	final func testGetRequestRatioTimeline() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: unauthenticatedInstance)
        try await handle.authenticate()
		let timeline = try await handle.getRequestRatioTimeline()

		XCTAssertGreaterThan(timeline.domains.count, 0)
		XCTAssertGreaterThan(timeline.ads.count, 0)
	}
	
	
	final func testGetForwardingDestinations() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let destinations = try await handle.getForwardDestinations()

		XCTAssertGreaterThan(destinations.count, 0)
		let total = destinations.values.reduce(0, +)
		XCTAssertEqual(total, 100, accuracy: 1)
	}

	final func testGetQueryTypes() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let types = try await handle.getQueryTypes()

		XCTAssertEqual(types.values.reduce(0,+), 100, accuracy: 1)
	}
	
	final func testGetHWInfo() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let info = try await handle.getHWInfo()

        XCTAssertNotNil(info.coreCount)
		XCTAssertNotNil(info.cpuTemp)
		XCTAssertNotNil(info.load1Min)
		XCTAssertNotNil(info.load5Min)
		XCTAssertNotNil(info.load15Min)
		XCTAssertNotNil(info.memoryUsage)
	}
	
	final func testGetClientTimeline() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		let clientTimeline = try await handle.getClientTimeline()

		XCTAssertGreaterThan(clientTimeline.clients.count, 0)
		XCTAssertGreaterThan(clientTimeline.timestamps.first!.value.count, 0)
		clientTimeline.timestamps.forEach {
			if $0.value.count != clientTimeline.clients.count {
				XCTFail("Timestamp client count mismatch")
			}
		}
	}

	final func testDisableEnableCycle() async throws {
		try XCTSkipIf(isXcodeServer)
        let handle = PHHandle(instance: authenticatedInstance)
        try await handle.authenticate()
		var response = try await handle.disable(for: 5)
		XCTAssertEqual(response, .disabled)
        try await Task.sleep(for: .seconds(0.1))
		response = try await handle.enable()
		XCTAssertEqual(response, .enabled)
        try await Task.sleep(for: .seconds(0.1))
		let summary = try await handle.getSummary()
		XCTAssertEqual(summary.state, .enabled)
	}
}
