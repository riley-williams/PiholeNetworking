//
//  PHClientTimeline.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHClientTimeline: Codable {
	/// List of clients active in the period represented
	public var clients: [PHClient]
	/// The array of counts corresponding to the `clients` property, keyed by timestamp
	public var timestamps: [TimeInterval:[Int]]
	
	enum CodingKeys: String, CodingKey {
		case clients
		case timestamps = "over_time"
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.clients = try container.decode([PHClient].self, forKey: .clients)
		let timestampStrings = try container.decode([String:[Int]].self, forKey: .timestamps)
		self.timestamps = [:]
		try timestampStrings.forEach {
			guard let timeInterval = TimeInterval($0.key)
			else {
				throw DecodingError.dataCorruptedError(forKey: .timestamps,
													   in: container,
													   debugDescription: "Unable to initialize TimeInterval from \"\($0.key)\"")
			}
			self.timestamps[timeInterval] = $0.value
		}
		
	}
}
