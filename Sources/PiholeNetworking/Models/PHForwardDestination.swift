//
//  PHForwardDestination.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Foundation

public enum PHForwardDestination: RawRepresentable {
	/// Destination reported for requests that hit the cache
	case cache
	/// Destination reported for requests that hit the blocklist
	case blocklist
	/// Remote forward destination
	case remote(name: String, ip: String)
	
	public init?(rawValue: String) {
		let components = rawValue.split(separator: "|")
		guard let nameComponent = components.first,
			  let ipComponent = components.last
		else { return nil }
		
		switch (nameComponent, ipComponent) {
		case ("cache", "cache"):
			self = .cache
		case ("blocklist", "blocklist"):
			self = .blocklist
		default:
			self = .remote(name: String(nameComponent), ip: String(ipComponent))
		}
	}
	
	public var rawValue: String {
		switch self {
		case .cache:
			return "cache|cache"
		case .blocklist:
			return "blocklist|blocklist"
		case .remote(name: let name, ip: let ip):
			return "\(name)|\(ip)"
		}
	}
}

extension PHForwardDestination: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .cache:
			hasher.combine("cache")
		case .blocklist:
			hasher.combine("blocklist")
		case .remote(name: let name, ip: let ip):
			hasher.combine("\(name)|\(ip)")
		}
	}
}
