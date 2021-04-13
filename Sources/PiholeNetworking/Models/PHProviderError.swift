//
//  PHProviderError.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation

public enum PHProviderError: Error {
	/// A different password may be required
	case authenticationRequired
	/// A URL could not be constructed using the hostname provided
	case invalidHostname
	case decodingError(DecodingError?)
	case urlError(URLError)
	case other(Error)
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
