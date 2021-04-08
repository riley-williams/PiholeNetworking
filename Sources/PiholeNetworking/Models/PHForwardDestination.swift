//
//  PHForwardDestination.swift
//  
//
//  Created by Riley Williams on 4/7/21.
//

import Foundation

public enum PHForwardDestination: Decodable {
	/// Destination reported for requests that hit the cache
	case cache
	/// Destination reported for requests that hit the blocklist
	case blocklist
	/// Remote forward destination
	case remote(name: String, ip: String)
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)
		let components = rawValue.split(separator: "|")
		guard let nameComponent = components.first,
			  let ipComponent = components.last
		else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected to find a single pipe | separator")) }
		
		switch (nameComponent, ipComponent) {
		case ("cache", "cache"):
			self = .cache
		case ("blocklist", "blocklist"):
			self = .blocklist
		default:
			self = .remote(name: nameComponent.stripPort(), ip: ipComponent.stripPort())
		}
	}
}

fileprivate extension StringProtocol {
	/// Given a string of the format: `abc#53` this strips the #53
	func stripPort() -> String {
		guard let strippedString = self.split(separator: "#").first
		else { return String(self) }
		return String(strippedString)
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
