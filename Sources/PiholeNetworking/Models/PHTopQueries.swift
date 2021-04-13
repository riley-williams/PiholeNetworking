//
//  PHTopQueries.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHTopQueries: Codable {
	public var topPassed: [String: Int]
	public var topBlocked: [String: Int]
	
	enum CodingKeys: String, CodingKey {
		case topPassed = "top_queries"
		case topBlocked = "top_ads"
	}
}
