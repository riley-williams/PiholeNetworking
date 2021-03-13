//
//  File.swift
//  
//
//  Created by Riley Williams on 3/13/21.
//

import Foundation

open struct PHStatus: Codable {
	var state:PHState = .unknown
	var blockedDomainCount:Int = 0
	var dnsQueryTodayCount:Int = 0
	var adsBlockedTodayCount:Int = 0
	var uniqueDomainCount:Int = 0
	var forwardedQueryCount:Int = 0
	var cachedQueryCount:Int = 0
	var totalClientsCount:Int = 0
	var uniqueClientCount:Int = 0
	var totalDNSCount:Int = 0
	var percentAdsToday:Float = 0
	
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
