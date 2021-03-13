//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PH10MinClientData: Codable {
	public var clients: [PHClient]
	public var timestamps: [String:[Int]]
	
	enum CodingKeys: String, CodingKey {
		case clients
		case timestamps = "over_time"
	}
}
