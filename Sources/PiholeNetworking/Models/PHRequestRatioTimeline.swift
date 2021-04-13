//
//  PHDomainData.swift
//  
//
//  Created by Riley Williams on 3/20/21.
//

import Foundation

public struct PHRequestRatioTimeline: Codable {
	/// Counts of blocked domain requests
	public var ads: [String: Int]
	/// Counts of passed domain requests
	public var domains: [String: Int]
	
	enum CodingKeys: String, CodingKey {
		case ads = "ads_over_time"
		case domains = "domains_over_time"
	}
}
