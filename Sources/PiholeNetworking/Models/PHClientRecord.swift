//
//  File.swift
//  
//
//  Created by Riley Williams on 3/21/21.
//

import Foundation

public struct PHClientRecord: Codable {
	/// Time this record was recorded
	public let timestamp: Int
	/// Number of requests from a specific client
	public let count: Int
	
	public init(timestamp: Int, count: Int) {
		self.timestamp = timestamp
		self.count = count
	}
}

