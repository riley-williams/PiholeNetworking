//
//  PHNetworkClient.swift
//  PiholeNetworking
//
//  Created by Riley Williams on 4/13/21.
//

import Foundation

/// A device tracked across time by Pi-hole
public struct PHNetworkClient: Decodable {
	/// The hardware address which identifies this client
	public var hardwareAddress: HardwareAddress
	/// The network interface this client is attached to
	public var interface: String
	/// The first date this client was seen
	public var firstSeen: Date
	/// The date of the most recent request
	public var lastQuery: Date
	/// The all-time number of requests made by this client
	public var queryCount: Int
	/// The vendor, as determined by mac address lookup
	public var vendor: String
	/// IP addresses used by this client, sometimes with names
	public var aliases: [PHClient]
	
	enum CodingKeys: String, CodingKey {
		case hardwareAddress = "hwaddr"
		case interface
		case firstSeen
		case lastQuery
		case queryCount = "numQueries"
		case vendor = "macVendor"
		case ip = "ip"
		case name = "name"
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let rawAddress = try container.decode(String.self, forKey: .hardwareAddress)
		guard let hardwareAddress = HardwareAddress(rawValue: rawAddress)
		else {
			throw DecodingError.dataCorruptedError(forKey: .hardwareAddress,
												   in: container,
												   debugDescription: "Unable to parse hardware address from \"\(rawAddress)\"")
		}
		self.hardwareAddress = hardwareAddress
		
		self.interface = try container.decode(String.self, forKey: .interface)
		self.firstSeen = try container.decode(Date.self, forKey: .firstSeen)
		self.lastQuery = try container.decode(Date.self, forKey: .lastQuery)
		self.queryCount = try container.decode(Int.self, forKey: .queryCount)
		self.vendor = try container.decode(String.self, forKey: .vendor)
		
		let ips = try container.decode([String].self, forKey: .ip)
		let names = try container.decode([String].self, forKey: .name)
			.map { $0.isEmpty ? nil : $0 }
		
		self.aliases = zip(ips, names)
			.map { PHClient(ip: $0, name: $1) }
	}
}

public extension PHNetworkClient {
	/// Represents a hardware address
	enum HardwareAddress: RawRepresentable, Hashable {
		/// MAC address
		case mac(String)
		/// IP address
		case ip(String)
		
		public init?(rawValue: String) {
			if rawValue.hasPrefix("ip-") {
				var ip = rawValue
				ip.removeFirst(3)
				self = .ip(ip)
				return
			} else if !rawValue.isEmpty {
				self = .mac(rawValue)
				return
			}
			return nil
		}
		
		public var rawValue: String {
			switch self {
			case .mac(let mac):
				return mac
			case .ip(let ip):
				return ip
			}
		}
	}
}

extension PHNetworkClient: Hashable {
	public static func == (lhs: PHNetworkClient, rhs: PHNetworkClient) -> Bool {
		lhs.hardwareAddress == rhs.hardwareAddress
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.hardwareAddress)
	}
}

//
//{
//"id": 22,
//"hwaddr": "52:54:00:4e:14:33",
//"interface": "eth0",
//"firstSeen": 1595913120,
//"lastQuery": 1610571652,
//"numQueries": 45,
//"macVendor": "Realtek (UpTech? also reported)",
//"aliasclient_id": null,
//"ip": [
//	"192.168.1.50",
//	"192.168.1.51",
//	"192.168.1.53"
//],
//"name": [
//	"",
//	"",
//	""
//]
//}
