//
//  PHClient.swift
//  Singularity
//
//  Created by Riley Williams on 6/3/20.
//  Copyright © 2020 Riley Williams. All rights reserved.
//

import Foundation

public struct PHClient {
	/// The IP address of this client
	public var ip: String
	/// The name associated with this client, typically postfixed with the search domain.
	/// e.g. `Mabbook-Pro.DOMAIN`
	public var name: String?
	
	public init(ip: String, name: String? = nil) {
		self.ip = ip
		self.name = name
	}
}

extension PHClient: Codable { }

extension PHClient: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ip)
	}
}

extension PHClient: Comparable {
	public static func < (lhs: PHClient, rhs: PHClient) -> Bool {
		let lhsName = lhs.name ?? ""
		let rhsName = rhs.name ?? ""
		if lhsName.isEmpty && !rhsName.isEmpty {
			return false
		} else if !lhsName.isEmpty && rhsName.isEmpty {
			return true
		} else if lhsName.isEmpty && rhsName.isEmpty {
			let lhsComponents = lhs.ip
				.components(separatedBy: ".")
				.map { String($0.reversed()) }
				.map { $0.padding(toLength: 3, withPad: "0", startingAt: 0) }
				.map { String($0.reversed()) }
				.reduce("", +)
			let rhsComponents = rhs.ip
				.components(separatedBy: ".")
				.map { String($0.reversed()) }
				.map { $0.padding(toLength: 3, withPad: "0", startingAt: 0) }
				.map { String($0.reversed()) }
				.reduce("", +)
			return lhsComponents < rhsComponents
		} else {
			return lhsName < rhsName
		}
	}
	
	public static func == (lhs: PHClient, rhs: PHClient) -> Bool {
		lhs.ip == rhs.ip
	}
}
