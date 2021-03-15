//
//  PHInstance.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import CryptoKit

public protocol PHInstance {
	var hostname: String { get }
	var port: Int { get }
	var password: String? { get }
}

extension PHInstance {
	var address: String { "\(hostname):\(port)" }
	
	var hashedPassword: String? {
		if let password = password,
		   let data = password.data(using: .utf8) {
			let hash = SHA256.hash(data: data)
			let stringifiedHash = hash.compactMap { String(format: "%02x", $0) }.joined().lowercased()
			if let data = stringifiedHash.data(using: .utf8) {
				let hash2 = SHA256.hash(data: data)
				let stringifiedHash2 = hash2.compactMap { String(format: "%02x", $0) }.joined().lowercased()
				return stringifiedHash2
			}
		}
		return nil
	}
}
