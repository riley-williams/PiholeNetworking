//
//  ConcreteInstance.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import PiholeNetworking
import Foundation

struct ConcreteInstance: PHInstance {
	var hostname: String
	var port: Int
	var password: String?

	init(hostname: String, port: Int = 80, password: String? = nil) {
		self.hostname = hostname
		self.port = port
		self.password = password
	}
}
