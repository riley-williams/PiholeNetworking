//
//  MockFailureSession.swift
//  PiholeNetworkingTests
//
//  Created by Riley Williams on 4/13/21.
//

import Foundation
import PiholeNetworking
import Combine

/// Always publishes the provided object, encoded with a JSON Encoder.
struct MockFailureSession: PHSession {
	var failure: URLError
	func simpleDataTaskPublisher(for: URL) async throws -> Data {
		throw failure
	}
}
