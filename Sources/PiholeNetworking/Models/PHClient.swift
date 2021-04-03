//
//  PHClient.swift
//  Singularity
//
//  Created by Riley Williams on 6/3/20.
//  Copyright © 2020 Riley Williams. All rights reserved.
//

import Foundation

public struct PHClient {
	public let name: String
	public let ip: String
	
	public init(name: String, ip: String) {
		self.name = name
		self.ip = ip
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
		if lhs.name.isEmpty && !rhs.name.isEmpty {
			return false
		} else if !lhs.name.isEmpty && rhs.name.isEmpty {
			return true
		} else if lhs.name.isEmpty && rhs.name.isEmpty {
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
			return lhs.name < rhs.name
		}
	}
	
	public static func == (lhs: PHClient, rhs: PHClient) -> Bool {
		lhs.ip == rhs.ip
	}
}
