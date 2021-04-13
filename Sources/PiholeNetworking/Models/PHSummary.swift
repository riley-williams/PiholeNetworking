//
//  PHSummary.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHSummary: Codable {
	public var state:PHState = .unknown
	/// The number of blacklisted domains
	public var blacklistSize:Int
	/// The number of dns queries served today that were not blocked
	public var queryCount:Int
	/// The total number of dns queries served today?
	//public var totalQueryCount:Int
	/// The number of dns queries blocked today
	public var blockedQueryCount:Int
	/// The number of unique domains resolved today
	public var uniqueDomainCount:Int
	/// The number of queries forwarded to an upstream resolver today
	public var forwardedQueryCount:Int
	/// The number of queries that were resolved by the cache today
	public var cachedQueryCount:Int
	/// The all-time number of unique clients seen
	public var allTimeClientCount:Int
	/// The number of unique clients seen today
	public var uniqueClientCount:Int
	/// The percentage of queries blocked today, ranging from 0 to 100
	public var percentAds:Float
	/// The configured log privacy level
	public var privacyLevel: Int
	/// Information about the gravity list
	public var gravityInfo: GravityInfo
	
	enum CodingKeys: String, CodingKey {
		case state = "status"
		case blacklistSize = "domains_being_blocked"
		case queryCount = "dns_queries_today"
		//case totalQueryCount = "dns_queries_all_types"
		case blockedQueryCount = "ads_blocked_today"
		case uniqueDomainCount = "unique_domains"
		case forwardedQueryCount = "queries_forwarded"
		case cachedQueryCount = "queries_cached"
		case allTimeClientCount = "clients_ever_seen"
		case uniqueClientCount = "unique_clients"
		case percentAds = "ads_percentage_today"
		case privacyLevel = "privacy_level"
		case gravityInfo = "gravity_last_updated"
	}
}

extension PHSummary {
	public struct GravityInfo: Codable {
		/// Whether the gravity file exists, may be an indicator of gravity health
		public var exists: Bool
		/// When gravity was last updated
		public var lastUpdate: Date
		
		enum CodingKeys: String, CodingKey {
			case exists = "file_exists"
			case lastUpdate = "absolute"
		}
	}
}

// Unconfigured properties
//{
//	"reply_NODATA": 39,
//	"reply_NXDOMAIN": 125,
//	"reply_CNAME": 1213,
//	"reply_IP": 2171,
//}
