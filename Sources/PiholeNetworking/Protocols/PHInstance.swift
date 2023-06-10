//
//  PHInstance.swift
//  
//
//  Created by Riley Williams on 3/14/21.
//

import Foundation
import CryptoKit

public protocol PHInstance {
	associatedtype IntType: BinaryInteger
	var ip: String { get }
	var port: IntType { get }
	var password: String { get }
}

public extension PHInstance {
	var address: String { "\(ip):\(port)" }
	
	/// API key used to access the Pi-hole API. This is generated from the password.
	/// If the password is nil, this will use an empty string as the password
	var apiKey: String? {
		guard let data = (password).data(using: .utf8) else { return nil }
		let stringifiedHash = SHA256.hash(data: data)
			.compactMap { String(format: "%02x", $0) }
			.joined()
			.lowercased()
		guard let hashData = stringifiedHash.data(using: .utf8) else { return nil }
		return SHA256.hash(data: hashData)
			.compactMap { String(format: "%02x", $0) }
			.joined()
			.lowercased()
	}
}

