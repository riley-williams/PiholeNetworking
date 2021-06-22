//
//  MockSession.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Foundation
import PiholeNetworking
import Combine

/// Always publishes the provided object, encoded with a JSON Encoder.
struct MockSession<T: StringProtocol>: PHSession {
	var result: T
	func simpleDataTaskPublisher(for: URL) async throws -> Data {
		guard let response = result.data(using: .utf8) else {
			throw PHProviderError.invalidHostname
		}
		return response
	}
}
