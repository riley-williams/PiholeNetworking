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
struct MockFailureSession: PHNetworkingProvider {
	var failure: URLError
    
    func dataTask(for: URLRequest) async throws -> (Data, URLResponse) {
        throw failure
    }
}
