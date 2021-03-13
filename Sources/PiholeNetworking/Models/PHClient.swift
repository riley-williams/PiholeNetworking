//
//  PHClient.swift
//  Singularity
//
//  Created by Riley Williams on 6/3/20.
//  Copyright © 2020 Riley Williams. All rights reserved.
//

import Foundation

public struct PHClient: Codable {
	public var name: String
	public var ip: String
	
	public init(name: String, ip: String) {
		self.name = name
		self.ip = ip
	}
}
