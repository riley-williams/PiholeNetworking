import XCTest
import Combine
@testable import PiholeNetworking

final class PiholeNetworkingTests: XCTestCase {
	let instance = ConcreteInstance(hostname: "256.0.0.0")
	var cancellables: Set<AnyCancellable> = []
	let session = mockSession
	override func setUp() {
		
	}
	
	final func testGetHardwareInfo() throws {
		let expectation = XCTestExpectation()
		
		PHProvider(session: session)
			.getHWInfo(instance)
			.sink { completion in
				expectation.fulfill()
			} receiveValue: { value in
				
			}.store(in: &cancellables)
		wait(for: [expectation], timeout: 3)
		
	}
	
	final func testGetStatus() throws {
		let expectation = XCTestExpectation()
		
		PHProvider(session: session)
			.getStatus(instance)
			.sink { completion in
				expectation.fulfill()
			} receiveValue: { status in
				XCTAssertEqual(status.state, .enabled)
				XCTAssertEqual(status.blockedDomainCount, 92_699)
			}.store(in: &cancellables)
		wait(for: [expectation], timeout: 3)
		
	}

	static var mockSession: URLSession {
		URLProtocolMock.testURLs = MockJSON.endpoints.mapValues { $0.data(using: .utf8)! }
		let config = URLSessionConfiguration.ephemeral
		config.protocolClasses = [URLProtocolMock.self]
		return URLSession(configuration: config)
	}
	
	//TODO: Why Apple :/
    static var allTests = [
        ("testGetHardwareInfo", testGetHardwareInfo),
    ]
}
