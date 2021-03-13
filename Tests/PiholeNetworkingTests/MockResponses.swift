import Foundation

enum MockJSON { }

extension MockJSON {
	static var status: String { endpoints["/admin"]! }
	
	static let endpoints = [
		"/admin":
	"""
	{
	 "domains_being_blocked": "92,699",
	 "dns_queries_today": "32,245",
	 "ads_blocked_today": "1,063",
	 "ads_percentage_today": "3.3",
	 "unique_domains": "5,037",
	 "queries_forwarded": "15,895",
	 "queries_cached": "15,285",
	 "clients_ever_seen": "20",
	 "unique_clients": "18",
	 "dns_queries_all_types": "32,245",
	 "reply_NODATA": "1,030",
	 "reply_NXDOMAIN": "1,760",
	 "reply_CNAME": "7,510",
	 "reply_IP": "17,792",
	 "privacy_level": "0",
	 "status": "enabled",
	 "gravity_last_updated": {
		 "file_exists": true,
		 "absolute": 1589299797,
		 "relative": {
			 "days": 2,
			 "hours": 9,
			 "minutes": 32
		 }
	 }
	}
	""",
	]
	
}
