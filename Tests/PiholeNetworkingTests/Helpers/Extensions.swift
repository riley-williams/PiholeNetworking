//
//  File.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Combine
import PiholeNetworking

extension Collection where Element: Cancellable {
	func cancelAll() {
		forEach { $0.cancel() }
	}
}

extension PHProviderError: Equatable {
	public static func == (lhs: PHProviderError, rhs: PHProviderError) -> Bool {
		switch (lhs, rhs) {
		case (.authenticationRequired, .authenticationRequired):
			return true
		case (.invalidHostname, .invalidHostname):
			return true
		case (.decodingError(_), .decodingError(_)):
			return true
		case (.urlError(let e1),.urlError(let e2)):
			return e1 == e2
		default:
			return false
		}
	}
}
