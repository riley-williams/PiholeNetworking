//
//  PHClient.swift
//  Singularity
//
//  Created by Riley Williams on 6/3/20.
//  Copyright © 2020 Riley Williams. All rights reserved.
//

import Foundation

public struct PHClient: Codable, CustomStringConvertible {
	var name: String
	var ip: String
	
	var description: String {
		return name.isEmpty ? ip : name
	}
}
