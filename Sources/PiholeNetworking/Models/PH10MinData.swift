//
//  File.swift
//  
//
//  Created by Riley Williams on 3/20/21.
//

import Foundation

public struct PH10MinData: Codable {
	public let ads: [String: Int]
	public let domains: [String: Int]
	
	enum CodingKeys: String, CodingKey {
		case ads = "ads_over_time"
		case domains = "domains_over_time"
	}
	
	public init(ads: [String : Int], domains: [String : Int]) {
		self.ads = ads
		self.domains = domains
	}
}
