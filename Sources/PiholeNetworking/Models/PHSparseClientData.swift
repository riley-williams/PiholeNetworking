//
//  File.swift
//  
//
//  Created by Riley Williams on 3/21/21.
//

import Foundation

public struct PHSparseClientData: Codable {
	/// Sparse results of historic client record activity
	public var records: [PHClient: [PHClientRecord]]
	
	public init(data: PH10MinClientData) {
		var records: [PHClient: [PHClientRecord]] = [:]
		// Seed the dictionary keys
		data.clients.forEach { records[$0] = [] }
		data.timestamps.forEach { (key, counts) in
			guard let timetamp = Int(key) else { return }
			zip(data.clients, counts).lazy
				.filter { $0.1 > 0 }
				.forEach { (client, count) in
					let record = PHClientRecord(timestamp: timetamp, count: count)
					records[client]?.append(record)
				}
		}
		self.records = records
	}
}


