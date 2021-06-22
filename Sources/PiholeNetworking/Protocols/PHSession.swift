//
//  PHSession.swift
//  
//
//  Created by Riley Williams on 4/3/21.
//

import Foundation
import Combine

public protocol PHSession {
	func simpleDataTaskPublisher(for: URL) async throws -> Data
}

extension URLSession: PHSession {
	public func simpleDataTaskPublisher(for url: URL) async throws -> Data {
		return try await self.data(from: url, delegate: nil).0
	}
}
