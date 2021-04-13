//
//  PiholeIntegrationTests.swift
//  PiholeNetworkingTests
//
//  Created by Riley Williams on 4/12/21.
//

import XCTest
import Combine
@testable import PiholeNetworking

class PiholeIntegrationTests: XCTestCase {
	var cancellables: Set<AnyCancellable> = []
	let unauthenticatedInstance = ConcreteInstance("192.168.1.11")
	let authenticatedInstance = ConcreteInstance("192.168.1.10", password: "8MzrcBRm")
	let provider = PHProvider()
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	final func testGetSummary() throws {
		let promise = XCTestExpectation()
		provider.getSummary(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { summary in
				XCTAssertGreaterThan(summary.dnsQueryTodayCount, 0)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testDecodeTopQueries() throws {
		let promise = XCTestExpectation()
		provider.getTopQueries(authenticatedInstance, count: 6)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { topQueries in
				XCTAssertLessThanOrEqual(topQueries.topPassed.count, 6)
				XCTAssertLessThanOrEqual(topQueries.topBlocked.count, 6)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testDecodeRequestRatioTimeline() throws {
		let promise = XCTestExpectation()
		provider.getRequestRatioTimeline(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { timeline in
				XCTAssertGreaterThan(timeline.domains.count, 0)
				XCTAssertGreaterThan(timeline.ads.count, 0)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetForwardingDestinations() throws {
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
				XCTAssertGreaterThan(destinations.count, 0)
				let total = destinations.values.reduce(0, +)
				XCTAssertEqual(total, 100, accuracy: 1)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetHWInfo() throws {
		let promise = XCTestExpectation()
		provider.getHWInfo(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { info in
				XCTAssertNotNil(info.cpuTemp)
				XCTAssertNotNil(info.load1Min)
				XCTAssertNotNil(info.load5Min)
				XCTAssertNotNil(info.load15Min)
				XCTAssertNotNil(info.memoryUsage)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetClientTimeline() throws {
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
				XCTAssertGreaterThan(clientTimeline.timestamps.first!.value.count, 0)
				clientTimeline.timestamps.forEach {
					if $0.value.count != clientTimeline.clients.count {
						XCTFail("Timestamp client count mismatch")
					}
				}
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}

	final func testValidatePassword() throws {
		let promise = XCTestExpectation()
		let promise2 = XCTestExpectation()
		provider.verifyPassword(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { respone in
				XCTAssertFalse(respone)
				promise.fulfill()
			}.store(in: &cancellables)
		provider.verifyPassword(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise2.fulfill()
				}
			} receiveValue: { respone in
				XCTAssertTrue(respone)
				promise2.fulfill()
			}.store(in: &cancellables)
		
		wait(for: [promise, promise2], timeout: 1)
	}
	
}
