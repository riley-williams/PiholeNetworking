//
//  DisposableMockSession.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Foundation
import PiholeNetworking
import Combine

struct DisposableMockSession: PHSession {
	var result: Data
	
	init(result: String) {
		self.result = result.data(using: .utf8)!
	}
	
	func simpleDataTaskPublisher(for: URL) -> AnyPublisher<Data, URLError> {
		return Just(result)
			.setFailureType(to: URLError.self)
			.eraseToAnyPublisher()
	}
}
