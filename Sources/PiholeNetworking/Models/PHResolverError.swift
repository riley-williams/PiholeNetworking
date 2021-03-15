//
//  File.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation

public enum PHResolverError: Error {
	case timeout
	case hostUnreacheable
	case badPassword
	case invalidHostname
	case decodingError
	case urlError(error: URLError)
	case other(error: Error)
}
