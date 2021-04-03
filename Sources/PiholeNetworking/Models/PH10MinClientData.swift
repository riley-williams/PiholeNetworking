//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PH10MinClientData: Codable {
	public let clients: [PHClient]
	public let timestamps: [String:[Int]]
	
	public init(clients: [PHClient], timestamps: [String:[Int]]) {
		self.clients = clients
		self.timestamps = timestamps
	}
	
	enum CodingKeys: String, CodingKey {
		case clients
		case timestamps = "over_time"
	}
}
