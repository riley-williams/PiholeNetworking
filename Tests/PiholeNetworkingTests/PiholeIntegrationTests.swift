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

	final func testGetSummary() throws {
		try XCTSkipIf(!isXcodeServer)
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
				XCTAssertGreaterThan(summary.queryCount, 0)
				let computedCount = Float(summary.blockedQueryCount)/Float(summary.queryCount)*100
				XCTAssertEqual(computedCount, summary.percentAds, accuracy: 0.5)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetTopQueries() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getTopQueries(authenticatedInstance, max: 6)
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
	
	final func testGetTopQueriesUnauthenticated() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getTopQueries(unauthenticatedInstance, max: 6)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, PHProviderError.authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { _ in
				XCTFail("Expected to not receive a valid response")
				promise.fulfill()
			}
			.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetTopBlockedClients() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getTopBlockedClients(authenticatedInstance, max: 3)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { clients in
				XCTAssertGreaterThan(clients.count, 0)
				XCTAssertLessThanOrEqual(clients.count, 3)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetTopClients() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getTopClients(authenticatedInstance, max: 3)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { clients in
				XCTAssertGreaterThan(clients.count, 0)
				XCTAssertLessThanOrEqual(clients.count, 3)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}

	final func testGetRequestRatioTimeline() throws {
		try XCTSkipIf(!isXcodeServer)
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
		try XCTSkipIf(!isXcodeServer)
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
	
	final func testGetForwardingDestinationsUnauthenticated() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getForwardDestinations(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, PHProviderError.authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { _ in
				XCTFail("Expected to not receive a valid response")
				promise.fulfill()
			}
			.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetQueryTypes() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getQueryTypes(authenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { types in
				XCTAssertEqual(types.values.reduce(0,+), 100, accuracy: 1)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testGetHWInfo() throws {
		try XCTSkipIf(!isXcodeServer)
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
		try XCTSkipIf(!isXcodeServer)
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
	
	final func testGetClientTimelineUnauthenticated() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.getClientTimeline(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, PHProviderError.authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { _ in
				XCTFail("Expected to not receive a valid response")
				promise.fulfill()
			}
			.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}

	final func testValidatePassword() throws {
		try XCTSkipIf(!isXcodeServer)
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
	
	@available(OSX 11.0, *)
	final func testDisableEnableCycle() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.disable(authenticatedInstance, for: 5)
			.flatMap { [unowned self] response -> AnyPublisher<PHState, PHProviderError> in
				XCTAssertEqual(response, .disabled)
				return self.provider.enable(authenticatedInstance)
			}.flatMap { [unowned self] response -> AnyPublisher<PHSummary, PHProviderError> in
				XCTAssertEqual(response, .enabled)
				return self.provider.getSummary(authenticatedInstance)
			}
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTFail(error.localizedDescription)
					promise.fulfill()
				}
			} receiveValue: { summary in
				XCTAssertEqual(summary.state, .enabled)
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 5)
	}
	
	final func testDisableUnauthenticated() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.disable(unauthenticatedInstance, for: 1)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, .authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { _ in
				XCTFail("Expected not to receive any values")
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
	
	final func testEnableUnauthenticated() throws {
		try XCTSkipIf(!isXcodeServer)
		let promise = XCTestExpectation()
		provider.enable(unauthenticatedInstance)
			.sink { completion in
				switch completion {
				case .finished: break
				case .failure(let error):
					XCTAssertEqual(error, .authenticationRequired)
					promise.fulfill()
				}
			} receiveValue: { _ in
				XCTFail("Expected not to receive any values")
				promise.fulfill()
			}.store(in: &cancellables)
		wait(for: [promise], timeout: 1)
	}
}
