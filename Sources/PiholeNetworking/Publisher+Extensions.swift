//
//  Publisher+Extensions.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Combine
import Foundation

internal extension Publisher {
	func mapPiholeNetworkingError() -> Publishers.MapError<Self, PHProviderError> {
		mapError {
			switch $0 {
			case let error as URLError:
				return .urlError(error)
			case let error as PHProviderError:
				return error
			case let error as DecodingError:
				return .decodingError(error)
			default:
				return .other($0)
			}
		}
	}
}
