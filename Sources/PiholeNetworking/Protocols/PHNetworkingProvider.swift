//
//  PHSession.swift
//  
//
//  Created by Riley Williams on 4/3/21.
//

import Foundation
import Combine

public protocol PHNetworkingProvider: Sendable {
	func dataTask(for: URLRequest) async throws -> (Data, URLResponse)
}

extension PHNetworkingProvider {
    public func simpleDataTaskPublisher(for url: URL) async throws -> Data {
        return try await dataTask(for: URLRequest(url: url)).0
    }
}

extension URLSession: PHNetworkingProvider {
	public func dataTask(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await data(for: request)
	}
}

