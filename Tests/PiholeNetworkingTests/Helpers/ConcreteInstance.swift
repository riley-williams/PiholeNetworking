//
//  ConcreteInstance.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import PiholeNetworking
import Foundation

class ConcreteInstance: PHInstance {
	var ip: String
	var port: Int
	var password: String?

	init(_ hostname: String, port: Int = 80, password: String? = nil) {
		self.ip = hostname
		self.port = port
		self.password = password
	}
}

extension ConcreteInstance: Comparable { }
extension ConcreteInstance: Hashable { }
