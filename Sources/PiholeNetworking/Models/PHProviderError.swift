//
//  PHProviderError.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation

public enum PHProviderError: Error {
	case authenticationRequired
	/// A URL could not be constructed using the hostname provided
	case invalidHostname
	case decodingError(DecodingError?)
	case urlError(URLError)
	case other(Error)
}
