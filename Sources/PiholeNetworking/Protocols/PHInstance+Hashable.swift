//
//  PHInstance+Hashable.swift
//  
//
//  Created by Riley Williams on 4/3/21.
//

import Foundation

extension PHInstance where Self: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ip)
		hasher.combine(port)
	}
}
