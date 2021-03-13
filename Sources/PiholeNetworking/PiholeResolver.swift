//
//  PiHoleResolver.swift
//  Singularity
//
//  Created by Riley Williams on 3/13/21.
//  Copyright © 2021 Riley Williams. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13, *)
@available(OSX 10.15, *)
@available(watchOS 5, *)
public protocol PiHoleResolver {
	/// Verifies the password is correct
	/// - Parameter password: web interface password
	
	func verifyPassword(_ password: String) -> AnyPublisher<Bool, Error>
	
	/// Immediately performs all pending batched requests
	func flushQueue()
	
	
}

public enum ResolverError: Error {
	case timeout
	case hostUnreacheable
	case badPassword
	case other(error: Error)
}
