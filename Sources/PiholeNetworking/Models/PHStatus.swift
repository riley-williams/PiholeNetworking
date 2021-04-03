//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHStatus: Codable {
	public var state:PHState = .unknown
	public var blockedDomainCount:Int
	public var dnsQueryTodayCount:Int
	public var adsBlockedTodayCount:Int
	public var uniqueDomainCount:Int
	public var forwardedQueryCount:Int
	public var cachedQueryCount:Int
	public var totalClientsCount:Int
	public var uniqueClientCount:Int
	public var totalDNSCount:Int
	public var percentAdsToday:Float
	
	public init(state:PHState = .unknown,
				blockedDomainCount:Int = 0,
				dnsQueryTodayCount:Int = 0,
				adsBlockedTodayCount:Int = 0,
				uniqueDomainCount:Int = 0,
				forwardedQueryCount:Int = 0,
				cachedQueryCount:Int = 0,
				totalClientsCount:Int = 0,
				uniqueClientCount:Int = 0,
				totalDNSCount:Int = 0,
				percentAdsToday:Float = 0) {
		self.blockedDomainCount = blockedDomainCount
		self.dnsQueryTodayCount = dnsQueryTodayCount
		self.adsBlockedTodayCount = adsBlockedTodayCount
		self.uniqueDomainCount = uniqueDomainCount
		self.forwardedQueryCount = forwardedQueryCount
		self.cachedQueryCount = cachedQueryCount
		self.totalClientsCount = totalClientsCount
		self.uniqueClientCount = uniqueClientCount
		self.totalDNSCount = totalDNSCount
		self.percentAdsToday = percentAdsToday
	}
	
	enum CodingKeys: String, CodingKey {
		case state = "status"
		case blockedDomainCount = "domains_being_blocked"
		case dnsQueryTodayCount = "dns_queries_today"
		case adsBlockedTodayCount = "ads_blocked_today"
		case uniqueDomainCount = "unique_domains"
		case forwardedQueryCount = "queries_forwarded"
		case cachedQueryCount = "queries_cached"
		case totalClientsCount = "clients_ever_seen"
		case uniqueClientCount = "unique_clients"
		case totalDNSCount = "dns_queries_all_types"
		case percentAdsToday = "ads_percentage_today"
	}
	
}
