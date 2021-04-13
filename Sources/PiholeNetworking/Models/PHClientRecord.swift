//
//  PHClientRecord.swift
//  
//
//  Created by Riley Williams on 3/21/21.
//

import Foundation

public struct PHClientRecord: Codable {
	/// Time this record was recorded
	public var timestamp: Int
	/// Number of requests from a specific client
	public var count: Int
}

