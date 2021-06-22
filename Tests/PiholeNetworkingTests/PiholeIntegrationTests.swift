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
	let unauthenticatedInstance = ConcreteInstance("192.168.1.11")
	let authenticatedInstance = ConcreteInstance("192.168.1.10", password: "8MzrcBRm")
	let provider = PHProvider()
	
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

	final func testGetSummary() async throws {
		try XCTSkipIf(!isXcodeServer)
		let summary = try await provider.getSummary(unauthenticatedInstance)
			
		XCTAssertGreaterThan(summary.queryCount, 0)
		let computedCount = Float(summary.blockedQueryCount)/Float(summary.queryCount)*100
		XCTAssertEqual(computedCount, summary.percentAds, accuracy: 0.5)
	}
	
	final func testGetTopQueries() async throws {
		try XCTSkipIf(!isXcodeServer)
		let topQueries = try await provider.getTopQueries(authenticatedInstance, max: 6)
			
		XCTAssertLessThanOrEqual(topQueries.topPassed.count, 6)
		XCTAssertLessThanOrEqual(topQueries.topBlocked.count, 6)
	}
	
	final func testGetTopQueriesUnauthenticated() async throws {
		try XCTSkipIf(!isXcodeServer)
		do {
		_ = try await provider.getTopQueries(unauthenticatedInstance, max: 6)
			XCTFail("Expected to not receive a valid response")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, PHProviderError.authenticationRequired)
		} catch {
			XCTFail("Expected .authenticationRequired, got: \(error)")
		}
	}
	
	final func testGetTopBlockedClients() async throws {
		try XCTSkipIf(!isXcodeServer)
		let clients = try await provider.getTopBlockedClients(authenticatedInstance, max: 3)
			
		XCTAssertGreaterThan(clients.count, 0)
		XCTAssertLessThanOrEqual(clients.count, 3)
	}
	
	final func testGetTopClients() async throws {
		try XCTSkipIf(!isXcodeServer)
		let clients = try await provider.getTopClients(authenticatedInstance, max: 3)

		XCTAssertGreaterThan(clients.count, 0)
		XCTAssertLessThanOrEqual(clients.count, 3)
	}

	final func testGetRequestRatioTimeline() async throws {
		try XCTSkipIf(!isXcodeServer)
		let timeline = try await provider.getRequestRatioTimeline(unauthenticatedInstance)
			
		XCTAssertGreaterThan(timeline.domains.count, 0)
		XCTAssertGreaterThan(timeline.ads.count, 0)
	}
	
	
	final func testGetForwardingDestinations() async throws {
		try XCTSkipIf(!isXcodeServer)
		let destinations = try await provider.getForwardDestinations(authenticatedInstance)
		
		XCTAssertGreaterThan(destinations.count, 0)
		let total = destinations.values.reduce(0, +)
		XCTAssertEqual(total, 100, accuracy: 1)
	}
	
	final func testGetForwardingDestinationsUnauthenticated() async throws {
		try XCTSkipIf(!isXcodeServer)
		do {
			_ = try await provider.getForwardDestinations(unauthenticatedInstance)
			XCTFail("Expected to not receive a valid response")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, PHProviderError.authenticationRequired)
		} catch {
			XCTFail("Expected .authenticationRequired, got: \(error)")
		}
	}
	
	final func testGetQueryTypes() async throws {
		try XCTSkipIf(!isXcodeServer)
		let types = try await provider.getQueryTypes(authenticatedInstance)
			
		XCTAssertEqual(types.values.reduce(0,+), 100, accuracy: 1)
	}
	
	final func testGetHWInfo() async throws {
		try XCTSkipIf(!isXcodeServer)
		let info = try await provider.getHWInfo(unauthenticatedInstance)
			
		XCTAssertNotNil(info.cpuTemp)
		XCTAssertNotNil(info.load1Min)
		XCTAssertNotNil(info.load5Min)
		XCTAssertNotNil(info.load15Min)
		XCTAssertNotNil(info.memoryUsage)
	}
	
	final func testGetClientTimeline() async throws {
		try XCTSkipIf(!isXcodeServer)
		let clientTimeline = try await provider.getClientTimeline(authenticatedInstance)
			
		XCTAssertGreaterThan(clientTimeline.clients.count, 0)
		XCTAssertGreaterThan(clientTimeline.timestamps.first!.value.count, 0)
		clientTimeline.timestamps.forEach {
			if $0.value.count != clientTimeline.clients.count {
				XCTFail("Timestamp client count mismatch")
			}
		}
	}
	
	final func testGetClientTimelineUnauthenticated() async throws {
		try XCTSkipIf(!isXcodeServer)
		do {
			_ = try await provider.getClientTimeline(unauthenticatedInstance)
			XCTFail("Expected to not receive a valid response")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, PHProviderError.authenticationRequired)
		} catch {
			XCTFail("Expected .authenticationRequired, got: \(error)")
		}
	}

	final func testValidatePassword() async throws {
		try XCTSkipIf(!isXcodeServer)

		async let unauthenticated = try provider.verifyPassword(unauthenticatedInstance)
		async let authenticated = try provider.verifyPassword(authenticatedInstance)
		
		let results = try await (unauthenticated, authenticated)
		
		XCTAssertFalse(results.0)
		XCTAssertTrue(results.1)
	}
	
	final func testDisableEnableCycle() async throws {
		try XCTSkipIf(!isXcodeServer)
		var response = try await provider.disable(authenticatedInstance, for: 5)
		XCTAssertEqual(response, .disabled)
		
		response = try await self.provider.enable(authenticatedInstance)
		XCTAssertEqual(response, .enabled)
		
		let summary = try await self.provider.getSummary(authenticatedInstance)
		XCTAssertEqual(summary.state, .enabled)
				
	}
	
	final func testDisableUnauthenticated() async throws {
		try XCTSkipIf(!isXcodeServer)
		do {
			_ = try await provider.disable(unauthenticatedInstance, for: 1)
			XCTFail("Expected to not receive a valid response")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, PHProviderError.authenticationRequired)
		} catch {
			XCTFail("Expected .authenticationRequired, got: \(error)")
		}
	}
	
	final func testEnableUnauthenticated() async throws {
		try XCTSkipIf(!isXcodeServer)
		do {
			_ = try await provider.enable(unauthenticatedInstance)
			XCTFail("Expected to not receive a valid response")
		} catch let error as PHProviderError {
			XCTAssertEqual(error, PHProviderError.authenticationRequired)
		} catch {
			XCTFail("Expected .authenticationRequired, got: \(error)")
		}
	}
}
