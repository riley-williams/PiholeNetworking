//
//  PiholeType+Extensions.swift
//
//  Created by Riley Williams on 4/3/21.
//  Copyright © 2021 Riley Williams. All rights reserved.
//

import Foundation

public extension PHInstance where Self: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
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
		
		if lhsComponents == rhsComponents {
			return lhs.port < rhs.port
		}
		return lhsComponents < rhsComponents
	}
	
	static func ==(lhs: Self, rhs: Self) -> Bool {
		return lhs.address == rhs.address && lhs.port == rhs.port
	}
}
