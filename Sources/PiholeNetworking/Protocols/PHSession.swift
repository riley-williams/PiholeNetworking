//
//  File.swift
//  
//
//  Created by Riley Williams on 4/3/21.
//

import Foundation
import Combine

public protocol PHSession {
	func simpleDataTaskPublisher(for: URL) -> AnyPublisher<Data, URLError>
}

extension URLSession: PHSession {
	public func simpleDataTaskPublisher(for url: URL) -> AnyPublisher<Data, URLError> {
		self.dataTaskPublisher(for: url)
			.map(\.data)
			.eraseToAnyPublisher()
	}
}
