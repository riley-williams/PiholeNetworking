//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHTopQueries: Codable {
	public let topPassed: [String: Int]
	public let topBlocked: [String: Int]
	
	public init(topPassed: [String: Int], topBlocked: [String: Int]) {
		self.topPassed = topPassed
		self.topBlocked = topBlocked
	}
	
	enum CodingKeys: String, CodingKey {
		case topPassed = "top_queries"
		case topBlocked = "top_ads"
	}
}
