//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

public struct PHStatus: Codable {
	public let state:PHState = .unknown
	public let blockedDomainCount:Int
	public let dnsQueryTodayCount:Int
	public let adsBlockedTodayCount:Int
	public let uniqueDomainCount:Int
	public let forwardedQueryCount:Int
	public let cachedQueryCount:Int
	public let totalClientsCount:Int
	public let uniqueClientCount:Int
	public let totalDNSCount:Int
	public let percentAdsToday:Float
	
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
