//
//  PHClientRecord.swift
//  
//
//  Created by Riley Williams on 3/21/21.
//

import Foundation

public struct PHClientRecord: Codable {
	/// The timestamp of this record, represented as seconds since 1970
	public var timestamp: TimeInterval
	/// Number of requests from a specific client
	public var count: Int
}
