//
//  Extensions.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Combine
import PiholeNetworking

extension PHHandleError: Equatable {
	public static func == (lhs: PHHandleError, rhs: PHHandleError) -> Bool {
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
